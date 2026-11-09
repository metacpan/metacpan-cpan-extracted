use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBI;
use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k119: a row survives a deploy that meets its table, or
# its column, under the lower-case spelling of the declared name.
#
# WHY it exists: t/99-diff-case-only-names.t pins that the diff refuses; only
# a server holds a row, and only a server says whether the RENAME the refusal
# names is a statement and whether it is the whole way out. The stock here is
# what a deploy before karr k110 left behind, or what somebody typed without
# quotes: the table useraccount with the column createdat and one row. The
# schema declares UserAccount and createdAt. Deploy->diff used to answer with
# CREATE TABLE "UserAccount" and DROP TABLE useraccount CASCADE, and for a
# column with ADD COLUMN "createdAt" and DROP COLUMN createdat; apply ran
# through and the row, or its value, was gone.
#
# Three claims:
#
#  1. diff and upgrade die with the refusal, naming the table (the table and
#     the column) in both spellings, and the row is still there;
#  2. the statements the refusal names are ones the server takes, and taking
#     them one refusal after the other -- table, column, the index of the
#     primary key -- ends in a diff with nothing left to do;
#  3. after that the schema reads the very row under its declared names.
#
# Everything happens in databases of this file's own (karr k81).

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });

{
  package T99::Result::UserAccount;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('UserAccount');
  __PACKAGE__->add_columns(
    id        => { data_type => 'bigint', is_nullable => 0 },
    createdAt => { data_type => 'text',   is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T99::Mixed;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(UserAccount => 'T99::Result::UserAccount');
}
{
  package T99::Result::Acct;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('acct');
  __PACKAGE__->add_columns(
    id        => { data_type => 'bigint', is_nullable => 0 },
    createdAt => { data_type => 'text',   is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T99::MixedColumn;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Acct => 'T99::Result::Acct');
}

# A private database holding @stock, and $class connected to it.
sub stock {
  my ($tag, $class, @stock) = @_;
  my $schema = $class->connect(PrivatePgDatabase->create($tag), @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for @stock;
  return ($schema, $dbh);
}

# The names of the relations of kind $kind in public.
sub relations {
  my ($dbh, $kind) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT c.relname FROM pg_catalog.pg_class c
    WHERE c.relnamespace = 'public'::pg_catalog.regnamespace AND c.relkind = ?
    ORDER BY 1}, undef, $kind);
}

# undef when there is no such table.
sub column_names {
  my ($dbh, $table) = @_;
  return scalar eval { $dbh->selectcol_arrayref(q{
    SELECT a.attname FROM pg_catalog.pg_attribute a
    WHERE a.attrelid = ?::pg_catalog.regclass AND a.attnum > 0 AND NOT a.attisdropped
    ORDER BY a.attnum}, undef, $table) };
}

# What a refusal says to do: the statements it sets apart, two blanks in.
sub way_out {
  my ($error) = @_;
  return grep { /\AALTER \S.* RENAME / } map { /^  (\S.*;)$/ ? $1 : () } split /\n/, $error;
}

# diff dies with the refusal; returns the message.
sub refused {
  my ($label, $schema, $kind, @names) = @_;
  my $diff = eval { $schema->pg_deploy->diff };
  my $error = $@;
  ok(!$diff, "$label: Deploy->diff dies")
    or diag "the diff was built:\n" . $diff->as_sql;
  like($error, qr/\Arefusing to diff: \Q$kind\E /, "$label: with a refusal that is about the $kind");
  like($error, qr/(?<![\w.])\Q$_\E(?![\w.])/, "$label: that names $_") for @names;
  return $error;
}

# ---------------------------------------------------------------------------
# The table
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t99table', 'T99::Mixed',
    'CREATE TABLE useraccount (id bigint PRIMARY KEY, createdat text)',
    q{INSERT INTO useraccount VALUES (1, 'kept')},
  );
  note 'server ' . $dbh->selectrow_array('SHOW server_version');

  my $row = sub { scalar eval { $dbh->selectall_arrayref('SELECT id, createdat FROM useraccount') } };

  # 1. Refused, and nothing happened.
  my $error = refused('table', $schema, table => 'public.useraccount', 'public.UserAccount');
  is_deeply($row->(), [ [ 1, 'kept' ] ], 'table: the row is still there after diff');

  ok(!eval { $schema->pg_deploy->upgrade; 1 }, 'table: upgrade dies as well');
  like($@, qr/\Arefusing to diff: table /, 'table: with the same refusal');
  is_deeply(relations($dbh, 'r'), ['useraccount'],
    'table: the database has the one table it had, under the name it had');
  is_deeply($row->(), [ [ 1, 'kept' ] ], 'table: the row is still there after upgrade');

  # 2. The way out, one refusal after the other.
  is_deeply([ way_out($error) ], [ 'ALTER TABLE public.useraccount RENAME TO "UserAccount";' ],
    'table: the refusal names the rename');
  ok(eval { $dbh->do($_) for way_out($error); 1 }, 'table: the server takes it') or diag $@;

  $error = refused('then its column', $schema,
    column => 'public.UserAccount.createdat', 'public.UserAccount.createdAt');
  is_deeply([ way_out($error) ],
    [ 'ALTER TABLE public."UserAccount" RENAME COLUMN createdat TO "createdAt";' ],
    'then its column: the refusal names the rename');
  ok(eval { $dbh->do($_) for way_out($error); 1 }, 'then its column: the server takes it') or diag $@;

  # The index of the primary key kept its name when the table got its new
  # one, and DROP INDEX is refused for it by the server: the constraint
  # requires it.
  $error = refused('then the index of its primary key', $schema,
    index => 'public.useraccount_pkey', 'public.UserAccount_pkey');
  is_deeply([ way_out($error) ],
    [ 'ALTER INDEX public.useraccount_pkey RENAME TO "UserAccount_pkey";' ],
    'then the index of its primary key: the refusal names the rename');
  ok(eval { $dbh->do($_) for way_out($error); 1 },
    'then the index of its primary key: the server takes it') or diag $@;

  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, 'after the three renames the diff is built') or diag $@;
  ok($diff && !$diff->has_changes, '... and finds nothing left to do')
    or diag $diff && $diff->as_sql;

  # 3. The row, under the declared names.
  is_deeply(relations($dbh, 'r'), ['UserAccount'], 'the table is called what the schema calls it');
  is_deeply(column_names($dbh, 'public."UserAccount"'), [qw( id createdAt )], '... and so are its columns');
  my $found = eval { $schema->resultset('UserAccount')->find(1) };
  ok($found, 'the schema finds the row') or diag $@;
  is($found && $found->get_column('createdAt'), 'kept', '... with the value it had all along');

  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# The column, in a table whose name is not in question
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t99column', 'T99::MixedColumn',
    'CREATE TABLE acct (id bigint PRIMARY KEY, createdat text)',
    q{INSERT INTO acct VALUES (1, 'kept')},
  );

  my $error = refused('column', $schema,
    column => 'public.acct.createdat', 'public.acct.createdAt');
  is_deeply(column_names($dbh, 'public.acct'), [qw( id createdat )],
    'column: the table has the columns it had after diff');

  ok(!eval { $schema->pg_deploy->upgrade; 1 }, 'column: upgrade dies as well');
  like($@, qr/\Arefusing to diff: column /, 'column: with the same refusal');
  is_deeply(column_names($dbh, 'public.acct'), [qw( id createdat )],
    'column: the table has the columns it had after upgrade');
  is_deeply(scalar eval { $dbh->selectall_arrayref('SELECT id, createdat FROM acct') }, [ [ 1, 'kept' ] ],
    'column: and the value is still in the row')
    or diag $@;

  is_deeply([ way_out($error) ],
    [ 'ALTER TABLE public.acct RENAME COLUMN createdat TO "createdAt";' ],
    'column: the refusal names the rename');
  ok(eval { $dbh->do($_) for way_out($error); 1 }, 'column: the server takes it') or diag $@;

  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff && !$diff->has_changes, 'column: after the rename the diff finds nothing left to do')
    or diag $diff ? $diff->as_sql : $@;
  my $found = eval { $schema->resultset('Acct')->find(1) };
  is($found && $found->get_column('createdAt'), 'kept',
    'column: the schema reads the value under the declared name') or diag $@;

  $schema->storage->disconnect;
}

done_testing;
