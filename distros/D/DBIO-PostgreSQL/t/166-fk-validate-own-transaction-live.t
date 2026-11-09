use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

LiveServer->require_server;

# LIVE test for karr k145: with the option foreign_keys_not_valid the
# VALIDATE CONSTRAINT runs after the COMMIT of the ADD CONSTRAINT ... NOT
# VALID, in a transaction of its own.
#
# Claims:
#  1. the VALIDATE starts in a fresh transaction: before it
#     txid_current_if_assigned() is NULL, while before the ADD ... NOT VALID's
#     own statement a transaction is open (the add is bracketed), measured on
#     the connection that runs the statements;
#  2. rows that break the key: apply dies naming the key, the key is there and
#     stays NOT VALID (convalidated false, the add was committed), and the
#     next diff offers the VALIDATE again;
#  3. the key of a good table ends valid.

my $serial = 0;

sub schema_class {
  my $name = 'T166::S' . ++$serial;
  no strict 'refs';
  my %cols = (Parent => [qw( id )], Child => [qw( id parent_id )]);
  my %table = (Parent => 'parent', Child => 'child');
  for my $source (sort keys %cols) {
    my $result = "${name}::Result::$source";
    @{"${result}::ISA"} = ('DBIO::Core');
    $result->load_components('PostgreSQL::Result');
    $result->table($table{$source});
    $result->add_columns(map { ($_ => { data_type => 'bigint', is_nullable => 0 }) } @{ $cols{$source} });
    $result->set_primary_key('id');
  }
  my $child = "${name}::Result::Child";
  $child->belongs_to(parent => "${name}::Result::Parent", 'parent_id');
  $child->pg_fk_constraints_from_rels(1);
  @{"${name}::ISA"} = ('DBIO::Schema');
  $name->load_components('PostgreSQL');
  $name->register_class($_ => "${name}::Result::$_") for keys %cols;
  return $name;
}

sub stock {
  my ($tag, @sql) = @_;
  my $schema = schema_class()->connect(PrivatePgDatabase->create($tag), { PrintError => 0, PrintWarn => 0 });
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for ('CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
    'INSERT INTO parent SELECT g FROM generate_series(1, 20) g',
    'INSERT INTO child SELECT g, g FROM generate_series(1, 20) g', @sql);
  return ($schema, $dbh);
}

sub fks {
  my ($dbh) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT conname || (CASE WHEN convalidated THEN ' valid' ELSE ' not valid' END)
    FROM pg_catalog.pg_constraint WHERE contype = 'f' ORDER BY 1});
}

# 1. the transaction of each statement
{
  my ($schema, $dbh) = stock('t166a');
  my @seen;
  $dbh->{Callbacks} = { do => sub {
    my ($h, $sql) = @_;
    return unless $sql =~ /\bCONSTRAINT\b/;
    my ($txid) = $h->selectrow_array('SELECT pg_catalog.txid_current_if_assigned()');
    push @seen, [ $sql =~ /VALIDATE/ ? 'validate' : 'add', $txid, $h->{AutoCommit} ? 1 : 0 ];
    return;
  } };
  my $deploy = $schema->pg_deploy(foreign_keys_not_valid => 1);
  my $diff = $deploy->diff;
  $deploy->apply($diff);
  delete $dbh->{Callbacks};

  is_deeply([ map { $_->[0] } @seen ], [qw( add validate )], 'the add runs, then the validate');
  is($seen[0][2], 0, '... the add is inside a transaction (AutoCommit off)');
  is($seen[1][2], 1, '... the validate is not (AutoCommit on: a transaction of its own)');
  is($seen[1][1], undef, '... and no transaction of the add is still open when it starts');
  is_deeply(fks($dbh), ['child_parent_id_fkey valid'], '... the key ends valid');
  $schema->storage->disconnect;
}

# 2. rows that break the key
{
  my ($schema, $dbh) = stock('t166b', 'INSERT INTO child VALUES (100, 99)');
  my $deploy = $schema->pg_deploy(foreign_keys_not_valid => 1);
  eval { $deploy->apply($deploy->diff) };
  like($@, qr/child_parent_id_fkey/, 'an orphan row: apply dies, naming the key');
  is_deeply(fks($dbh), ['child_parent_id_fkey not valid'],
    '... the add was committed: the key is there and stays NOT VALID');
  my $again = $schema->pg_deploy(foreign_keys_not_valid => 1)->diff;
  is_deeply([ map { $_->as_sql } @{ $again->operations } ],
    ['ALTER TABLE public.child VALIDATE CONSTRAINT child_parent_id_fkey;'],
    '... and the next diff offers the VALIDATE again');
  $dbh->do('DELETE FROM child WHERE id = 100');
  $schema->pg_deploy(foreign_keys_not_valid => 1)->upgrade;
  is_deeply(fks($dbh), ['child_parent_id_fkey valid'], '... cleaned up, the next upgrade validates it');
  $schema->storage->disconnect;
}

done_testing;
