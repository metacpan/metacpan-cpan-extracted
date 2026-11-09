use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff::Column;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

LiveServer->require_server;

# LIVE test for karr dbio-postgresql-postgis k28: a USING hook turns a type
# change the server cannot cast on its own (text to integer) into one it runs.

{
  package T132L::Result::R;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('t');
  __PACKAGE__->add_columns(
    id => { data_type => 'bigint', is_nullable => 0 },
    v  => { data_type => 'bigint', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T132L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('public');
  __PACKAGE__->register_class(T => 'T132L::Result::R');
}

my $C = 'DBIO::PostgreSQL::Diff::Column';

my @db  = PrivatePgDatabase->create('t132');
my $dbh = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });
$dbh->do($_) for
  'CREATE TABLE t (id bigint PRIMARY KEY, v text)',
  q{INSERT INTO t VALUES (1, '42'), (2, '7'), (3, NULL)};
$dbh->disconnect;

my $schema = T132L::Schema->connect(@db, { PrintError => 0, PrintWarn => 0 });

# Without a hook the server refuses the cast: the upgrade fails.
{
  my $diff = $schema->pg_deploy->diff;
  unlike($diff->as_sql, qr/USING/, 'no hook: no USING');
  # text to bigint is lossy, so it is released: the refusal is the server's
  ok(!eval { $schema->pg_deploy->apply($diff, allow_destructive => 1); 1 }, 'no hook: the server refuses');
  like($@, qr/cannot be cast automatically/, '... with its own words, not the guard\'s');
}

$C->register_using_hook(t132 => sub { "$_[0]{column}::bigint" });
eval {
  my $diff = $schema->pg_deploy->diff;
  like($diff->as_sql, qr/TYPE bigint USING v::bigint;/, 'hook: USING in the ALTER');
  ok(eval { $schema->pg_deploy->apply($diff, allow_destructive => 1); 1 }, 'hook: the upgrade runs (a USING makes the change lossy)') or diag $@;
  my $d = $schema->storage->dbh;
  is_deeply($d->selectcol_arrayref('SELECT v FROM t ORDER BY id'), [ 42, 7, undef ],
    'the values were converted');
  is(scalar $d->selectrow_array(q{SELECT format_type(atttypid, atttypmod) FROM pg_attribute
    WHERE attrelid = 't'::regclass AND attname = 'v'}), 'bigint', 'the column is bigint');
  1;
} or diag $@;
$C->unregister_using_hook('t132');
$schema->storage->disconnect;

done_testing;
