#!/usr/bin/env perl
# t/63-quack-client-catalog.t -- karr k35: what a quack-attached catalog shows
# the client, measured on libduckdb 1.5.3. This is the extension's behaviour,
# not the driver's; the test pins it so a changed extension is noticed (a
# failing "is" below means the CLAUDE.md / POD notes need a second look, and
# probably got better).
use strict;
use warnings;
use Test::More;
use DBI;

my $probe = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '',
  { RaiseError => 0, PrintError => 0 })
  or plan skip_all => 'Cannot connect to DuckDB';
{
  local $probe->{RaiseError} = 0;
  local $probe->{PrintError} = 0;
  $probe->do('INSTALL quack') && $probe->do('LOAD quack')
    or plan skip_all => 'quack extension unavailable (needs libduckdb >= 1.5)';
}
$probe->disconnect;

use DBIO::Test::Schema;

my $connect = sub {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::DuckDB::Storage');
  return $schema->connect('dbi:DuckDB:dbname=:memory:')->storage;
};

my $PORT  = 9506;
my $addr  = "quack:localhost:$PORT";
my $token = 'catalog-token';

my $server = $connect->();
my $sdbh   = $server->dbh;
$sdbh->do('CREATE TABLE early (id INTEGER)');

eval { $server->quack_serve($addr, token => $token) };
plan skip_all => "quack_serve failed (port $PORT in use or other error): $@" if $@;

my $client = $connect->();
$client->quack_attach($addr, as => 'rem', token => $token);
my $dbh = $client->dbh;

# Run $sql on the client; returns (rows|undef, first line of the error).
my $try = sub {
  my ($sql) = @_;
  my $rows = eval { $dbh->selectall_arrayref($sql) };
  (my $err = $@ // '') =~ s/\n.*//s;
  return ($rows, $err);
};

# --- 1. the database listings throw, the schema listings do not ----------
for my $sql (
  'SELECT database_name FROM duckdb_databases()',
  'PRAGMA database_list',
  'SHOW DATABASES',
) {
  my ($rows, $err) = $try->($sql);
  ok !$rows && $err =~ /InMemory not implemented yet/,
    "$sql throws with a quack catalog attached"
    or diag $rows ? 'it answered now: the note in CLAUDE.md is out of date' : $err;
}

my ($rows) = $try->(q{SELECT schema_name FROM information_schema.schemata
                      WHERE catalog_name = 'rem'});
is_deeply $rows, [['main']], 'information_schema.schemata lists the alias';
($rows) = $try->(q{SELECT schema_name FROM duckdb_schemas()
                   WHERE database_name = 'rem'});
is_deeply $rows, [['main']], 'duckdb_schemas() lists the alias';

($rows) = $try->(q{SELECT table_name FROM information_schema.tables
                   WHERE table_catalog = 'rem'});
is_deeply $rows, [], 'information_schema.tables shows none of its tables';

# --- 2. tables created on the server after the ATTACH ---------------------
($rows) = $try->('SELECT COUNT(*) FROM rem.early');
is $rows && $rows->[0][0], 0, 'a table that existed at attach time is readable';

$sdbh->do('CREATE TABLE late (id INTEGER)');
$sdbh->do('INSERT INTO early VALUES (1)');

($rows) = $try->('SELECT COUNT(*) FROM rem.early');
is $rows && $rows->[0][0], 1, 'rows added to an existing table are read live';

my $err;
($rows, $err) = $try->('SELECT * FROM rem.late');
ok !$rows && $err =~ /Table with name late does not exist/,
  'a table created on the server after the ATTACH is invisible to the client'
  or diag $rows ? 'the client sees it now: the note in CLAUDE.md is out of date' : $err;

($rows, $err) = $try->('SELECT * FROM rem.late');
ok !$rows, 'and it stays invisible on a second query: no lazy refresh';

# --- 3. detach + attach again, or a second alias, takes a new snapshot ---
$client->quack_attach($addr, as => 'rem2', token => $token);
($rows, $err) = $try->('SELECT * FROM rem2.late');
ok $rows, 'a second alias for the same server sees the table' or diag $err;
($rows) = $try->('SELECT * FROM rem.late');
ok !$rows, 'while the first alias still does not';
$client->quack_detach('rem2');

$client->quack_detach('rem');
$client->quack_attach($addr, as => 'rem', token => $token);
($rows, $err) = $try->('SELECT * FROM rem.late');
ok $rows, 'quack_detach + quack_attach refreshes the catalog' or diag $err;

done_testing;
