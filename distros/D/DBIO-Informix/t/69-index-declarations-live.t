use strict;
use warnings;
use Test::More;
use DBIO::Optional::Dependencies ();

# LIVE half of karr k25 (core ADR 0061): an index declared canonically (Cake
# idx / indices, add_index_declaration) is created by install, an upgrade of a
# database that holds the table without it creates it, the server reads it
# back, and the diff of the same schema then has nothing left to say. Plain,
# unique and multi-column indexes. The offline half is t/42.
# Creates and drops only the table "zz_ix_k25_doc".

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');
my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run this test' unless $dsn;

use DBIO::Informix::Deploy;
use DBIO::Informix::Introspect;

my $n = 0;
sub schema_for {
  my ($with_idx) = @_;
  my $ns = 'K25Live::V' . ++$n;
  eval "package $ns; use base 'DBIO::Schema'; __PACKAGE__->storage_type('DBIO::Informix::Storage'); 1" or die $@;
  my $class = "${ns}::Result::Doc";
  eval "package $class; use base 'DBIO::Core'; 1" or die $@;
  $class->table('zz_ix_k25_doc');
  $class->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 64 },
    slug => { data_type => 'varchar', size => 64 },
  );
  $class->set_primary_key('id');
  if ($with_idx) {
    my $source = $class->result_source_instance;
    $source->add_index_declaration({ name => 'zz_ix_k25_name', columns => ['name'] });
    $source->add_index_declaration({ name => 'zz_ix_k25_slug', columns => ['slug'], type => 'unique' });
    $source->add_index_declaration({ name => 'zz_ix_k25_two', columns => ['slug', 'name'] });
  }
  $ns->register_class(Doc => $class);
  return $ns->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
}

my $first = schema_for(0);
my $dbh = $first->storage->dbh;
sub cleanup { eval { $dbh->do('DROP TABLE zz_ix_k25_doc') } }
cleanup();
END { cleanup() if $dbh }

sub server_indexes {
  my $m = DBIO::Informix::Introspect->new(dbh => $dbh)->model;
  my $ix = $m->{indexes}{zz_ix_k25_doc} // {};
  return { map { $_ => ($ix->{$_}{unique} ? 'unique' : 'plain') . ':' . join(',', @{ $ix->{$_}{columns} }) }
           grep { /^zz_ix_k25_/ } keys %$ix };
}
sub ours { my ($op) = @_; ($op->can('table_name') ? $op->table_name : '') eq 'zz_ix_k25_doc' }

ok eval { DBIO::Informix::Deploy->new(schema => $first)->install; 1 }, 'the schema without indexes installs' or diag $@;
is_deeply server_indexes(), {}, 'to begin with the table has no declared index';

my $after = schema_for(1);
ok eval { DBIO::Informix::Deploy->new(schema => $after)->upgrade; 1 }, 'the upgrade to the schema with idx runs' or diag $@;
is_deeply server_indexes(), {
  zz_ix_k25_name => 'plain:name', zz_ix_k25_slug => 'unique:slug', zz_ix_k25_two => 'plain:slug,name',
}, 'the upgrade created the declared indexes, also the non-unique and the multi-column one';

my $diff = eval { DBIO::Informix::Deploy->new(schema => schema_for(1))->diff };
my @own = $diff ? grep { ours($_) } @{ $diff->operations } : ();
ok $diff && !@own, 'and the diff has nothing left' or diag $diff ? join("\n", map { $_->as_sql } @own) : "the diff failed: $@";

# a fresh install of the same schema writes the same
cleanup();
ok eval { DBIO::Informix::Deploy->new(schema => schema_for(1))->install; 1 }, 'a fresh install with the indexes runs' or diag $@;
is scalar(keys %{ server_indexes() }), 3, '... and has all three';

done_testing;
