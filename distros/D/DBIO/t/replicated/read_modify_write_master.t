use strict;
use warnings;

use Test::More;

use DBIO::Test;

# OFFLINE (karr k390, ADR 0076). Under DBIO::Replicated a read that decides a
# write has to see what the master sees: replication lag on a replicant would
# turn "the row is not there" into a duplicate insert, and a lock taken on a
# replicant locks nothing the writers contend for.
#
# What this file claims:
#   1. find_or_create, find_or_new, update_or_create, update_or_new and the
#      upsert fallback read their lookup on the master;
#   2. a select with a lock attribute (for => 'update', 'shared', any defined
#      value) is answered by the master;
#   3. an ordinary search, find and count stay on the replicant;
#   4. a storage that names no pool for the lookup (not replicated) adds
#      nothing to the attributes of the lookup.
#
# THE SUBSTITUTIONS: DBIO::Test::Storage backends for master and replicant,
# the master holds the row, the replicant is the lagging one without it.

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => {
    '+DBIO::Replicated::Storage' => {
      backend_storage_class => 'DBIO::Test::Storage',
      balancer_type         => 'DBIO::Replicated::Balancer::First',
    },
  },
);

my ($replicant) = $schema->storage->connect_replicants(
  [ 'dbi:Test:replicant_one', '', '', { AutoCommit => 1 } ],
);

my $master_storage    = $schema->storage->master->storage;
my $replicant_storage = $replicant->storage;

$master_storage->mock_persistent(
  qr/SELECT .* FROM "artist"/i,
  [[ 1, 'On The Master', 13, undef ]],
);

sub reads {
  my ($storage) = @_;
  return scalar grep { /^\s*SELECT/i } map { $_->[0] } $storage->captured_sql_bind;
}

sub landing {
  my ($code) = @_;
  $master_storage->reset_captured;
  $replicant_storage->reset_captured;
  $code->();
  return ( reads($master_storage), reads($replicant_storage) );
}

my $artists = $schema->resultset('Artist');

my %on_master = (
  find_or_create => sub { $artists->find_or_create({ artistid => 1, name => 'x' }, { key => 'primary' }) },
  find_or_new    => sub { $artists->find_or_new({ artistid => 1, name => 'x' }, { key => 'primary' }) },
  update_or_create => sub { $artists->update_or_create({ artistid => 1, name => 'y' }, { key => 'primary' }) },
  update_or_new    => sub { $artists->update_or_new({ artistid => 1, name => 'y' }, { key => 'primary' }) },
  'upsert fallback' => sub {
    $artists->upsert({ artistid => 1, name => 'y' }, { fallback => 'update_or_create' });
  },
  'search for => update' => sub { $artists->search({}, { for => 'update' })->all },
  'search for => shared' => sub { $artists->search({}, { for => 'shared' })->all },
  'single for => update' => sub { $artists->search({ artistid => 1 }, { for => 'update' })->single },
);

for my $name (sort keys %on_master) {
  my ($m, $r) = landing($on_master{$name});
  cmp_ok $m, '>=', 1, "$name: the read is answered by the master";
  is $r, 0, "$name: ... and not by the replicant";
}

my %on_replicant = (
  'search'        => sub { $artists->search({ name => 'z' })->all },
  'find'          => sub { $artists->find(1) },
  'first'         => sub { $artists->search({ name => 'z' })->first },
  'search for undef' => sub { $artists->search({}, { for => undef })->all },
);

for my $name (sort keys %on_replicant) {
  my ($m, $r) = landing($on_replicant{$name});
  is $m, 0, "$name: the master is not asked";
  cmp_ok $r, '>=', 1, "$name: the replicant answers";
}

# 4. A storage without a replicated pool adds nothing.
{
  my $plain = DBIO::Test->init_schema( no_deploy => 1 );
  is $plain->storage->_read_pool_for_read_modify_write, undef,
    'a storage that is not replicated names no pool for the lookup';
  my $attrs = $plain->resultset('Artist')->_read_modify_write_attrs({ key => 'primary' });
  is_deeply $attrs, { key => 'primary' }, '... and the lookup attributes stay as given';
}

is $schema->storage->_read_pool_for_read_modify_write, 'master',
  'the replicated storage names the master';

done_testing;
