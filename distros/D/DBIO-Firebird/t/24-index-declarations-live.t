use strict;
use warnings;
use Test::More;

# LIVE half of karr k51 (core k333, ADR 0061): an index declared canonically
# (Cake idx / indices, add_index_declaration) is created by install, an upgrade
# of a database that holds the table without it creates it, and the diff of
# the same schema then has nothing left to say. The offline half is
# t/48-index-declarations.t.
#
# Skipped unless a DSN is provided (as t/19):
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# WARNING: creates and drops the table "k51_doc".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live index declaration test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Deploy;

my $other = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
}) or plan skip_all => 'Cannot connect: ' . DBI->errstr;
$other->func(-lock_resolution => { wait => 10 }, 'ib_set_tx_param');

my $n = 0;
sub schema_for {
  my ($with_idx) = @_;
  my $ns = 'K51Live::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('Firebird'); 1" or die $@;
  my $class = "${ns}::Result::Doc";
  eval "package $class; use DBIO 'Core'; 1" or die $@;
  $class->table('k51_doc');
  $class->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 64 },
    slug => { data_type => 'varchar', size => 64 },
  );
  $class->set_primary_key('id');
  if ($with_idx) {
    my $source = $class->result_source_instance;
    $source->add_index_declaration({ name => 'k51_idx_name', columns => ['name'] });
    $source->add_index_declaration({ name => 'k51_idx_slug', columns => ['slug'], type => 'unique' });
  }
  $ns->register_class(Doc => $class);
  return $ns->connect($dsn, $user, $pass, { quote_names => 1, on_connect_call => 'use_softcommit' });
}

sub server_indexes {
  my $rows = $other->selectall_arrayref(q{
    SELECT TRIM(rdb$index_name), rdb$unique_flag FROM rdb$indices
    WHERE rdb$relation_name = 'k51_doc' AND rdb$index_name STARTING WITH 'k51_'
  });
  return { map { $_->[0] => $_->[1] ? 'unique' : 'plain' } @$rows };
}

sub cleanup {
  eval { $other->do('DROP TABLE "k51_doc"') };
}

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on / };

cleanup();

my $before = schema_for(0);
ok eval { DBIO::Firebird::Deploy->new(schema => $before)->install; 1 },
  'the schema without indexes installs' or diag $@;
$before->storage->disconnect;
is_deeply server_indexes(), {}, 'to begin with the table has no declared index';

my $after = schema_for(1);
ok eval { DBIO::Firebird::Deploy->new(schema => $after)->upgrade; 1 },
  'the upgrade to the schema with idx runs' or diag $@;
$after->storage->disconnect;
is_deeply server_indexes(), { k51_idx_name => 'plain', k51_idx_slug => 'unique' },
  'the upgrade created the declared indexes';

my $again = schema_for(1);
my $diff = eval { DBIO::Firebird::Deploy->new(schema => $again)->diff };
ok $diff && !$diff->has_changes, 'and the diff has nothing left'
  or diag $diff ? $diff->as_sql : "the diff failed: $@";
$again->storage->disconnect;

cleanup();
$other->disconnect;
done_testing;
