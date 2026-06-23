#!/usr/bin/env perl
# t/60-quack.t — DBIO::DuckDB::Storage quack escape hatches.
# Skips cleanly when libduckdb < 1.5 (quack extension unavailable).
# To run with quack: DUCKDB_NO_ALIEN=1 LD_LIBRARY_PATH=/tmp/duckdb15 prove -lv t/60-quack.t

use strict;
use warnings;
use Test::More;
use DBI;

# ---- availability probe ------------------------------------------------
# Connect a bare in-memory DBI handle (not through DBIO) to check for quack.
# If the extension is missing we skip rather than fail -- quack is optional.
my $probe_dbh = DBI->connect(
  'dbi:DuckDB:dbname=:memory:', '', '',
  { RaiseError => 0, PrintError => 0, AutoCommit => 1 },
) or plan skip_all => 'Cannot connect to DuckDB: ' . ($DBI::errstr // '');

{
  local $probe_dbh->{RaiseError} = 0;
  local $probe_dbh->{PrintError} = 0;
  my $ok = eval {
    $probe_dbh->do('INSTALL quack') or die 'INSTALL quack failed';
    $probe_dbh->do('LOAD quack')   or die 'LOAD quack failed';
    1;
  };
  unless ($ok) {
    $probe_dbh->disconnect;
    plan skip_all => 'quack extension unavailable (needs libduckdb >= 1.5)';
  }
}
$probe_dbh->disconnect;

# ---- real tests --------------------------------------------------------
use DBIO::DuckDB::Storage;
use DBIO::DuckDB::Test;

my $PORT = 9501;

# -- server side: raw DBI so we can CALL quack_serve without tying up
#    a DBIO schema connection.
my $srv_dbh = DBI->connect(
  'dbi:DuckDB:dbname=:memory:', '', '',
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 },
) or die "server DBI connect failed: $DBI::errstr";

$srv_dbh->do('INSTALL quack');
$srv_dbh->do('LOAD quack');

# Create a test table on the server.
$srv_dbh->do(q{
  CREATE TABLE hello (
    id   INTEGER PRIMARY KEY,
    s    VARCHAR NOT NULL
  )
});
$srv_dbh->do(q{INSERT INTO hello VALUES (1, 'hello from server')});

my $quack_addr = "quack:localhost:$PORT";
eval {
  $srv_dbh->do("CALL quack_serve('$quack_addr', token => 'testtoken')");
};
if ($@) {
  $srv_dbh->disconnect;
  plan skip_all => "quack_serve failed (port $PORT in use or other error): $@";
}

ok 1, 'quack_serve started server on ' . $quack_addr;

# -- client side: use DBIO::DuckDB::Storage escape hatches
my $cli_schema = DBIO::DuckDB::Test->init_schema(no_populate => 1, no_deploy => 1);
my $storage    = $cli_schema->storage;

# quack_attach via storage method
eval { $storage->quack_attach($quack_addr, as => 'remote', token => 'testtoken') };
is $@, '', 'quack_attach did not die';

# Read a row from the remote catalog
my $dbh = $storage->dbh;
my $rows = $dbh->selectall_arrayref(
  'SELECT id, s FROM remote.hello ORDER BY id',
  { Slice => {} },
);
is ref $rows, 'ARRAY', 'selectall returns arrayref';
is scalar @$rows, 1, 'got 1 row from remote.hello';
is $rows->[0]{id}, 1,                    'id = 1';
is $rows->[0]{s},  'hello from server',  's column correct';

# Write via client, read back from server
$dbh->do(q{INSERT INTO remote.hello VALUES (2, 'written by client')});
my ($cnt) = $srv_dbh->selectrow_array('SELECT COUNT(*) FROM hello');
is $cnt, 2, 'server sees the row written by client';

# PRAGMA table_info works for remote quack catalog
my $info = $dbh->selectall_arrayref(
  'PRAGMA table_info(\'remote.hello\')',
  { Slice => {} },
);
is ref $info, 'ARRAY', 'PRAGMA table_info returns arrayref';
my %col_by_name = map { $_->{name} => $_ } @$info;
ok exists $col_by_name{id},  'id column in PRAGMA table_info';
ok exists $col_by_name{s},   's column in PRAGMA table_info';
is $col_by_name{id}{pk},     1, 'id is primary key in PRAGMA output';
is $col_by_name{s}{notnull}, 1, 's is NOT NULL in PRAGMA output';

# quack_detach
eval { $storage->quack_detach('remote') };
is $@, '', 'quack_detach did not die';

# After detach, querying remote should fail. We create a fresh bare DBI
# handle so DBIO's HandleError callback does not intercept the error.
{
  my $bare = DBI->connect(
    'dbi:DuckDB:dbname=:memory:', '', '',
    { RaiseError => 0, PrintError => 0, AutoCommit => 1 },
  );
  # bare connection has no remote attached, so remote.hello must fail
  my $res = $bare->do('SELECT * FROM remote.hello');
  ok !defined $res, 'remote.hello inaccessible without attach';
  $bare->disconnect;
}

# ---- validation / croak tests ------------------------------------------
eval { $storage->quack_serve('notquack:localhost', token => 'x') };
like $@, qr/must start with 'quack:'/, 'quack_serve croaks on bad addr prefix';

eval { $storage->quack_serve("quack:localhost:9502'--") };
like $@, qr/must not contain single quotes/, 'quack_serve croaks on single quote in addr';

eval { $storage->quack_attach('quack:localhost:9502', as => '1invalid') };
like $@, qr/invalid catalog alias/, 'quack_attach croaks on invalid alias';

eval { $storage->quack_attach('quack:localhost:9502') };
like $@, qr/"as" option/, 'quack_attach croaks when as is missing';

eval { $storage->quack_detach('1bad') };
like $@, qr/invalid catalog name/, 'quack_detach croaks on invalid name';

# ---- connect_call_quack_attach validation ------------------------------
eval { $storage->connect_call_quack_attach('not-a-hashref') };
like $@, qr/hashref argument required/, 'connect_call_quack_attach croaks on non-hashref';

eval { $storage->connect_call_quack_attach({}) };
like $@, qr/"addr" required/, 'connect_call_quack_attach croaks when addr missing';

$srv_dbh->disconnect;

done_testing;
