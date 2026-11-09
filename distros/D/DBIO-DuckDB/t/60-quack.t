#!/usr/bin/env perl
# t/60-quack.t — DBIO::DuckDB::Storage quack escape hatches.
# Skips cleanly when libduckdb < 1.5 (quack extension unavailable).
# With Alien::DuckDB >= 0.04 (libduckdb 1.5.3) this runs stock; only with an
# older Alien: DUCKDB_NO_ALIEN=1 LD_LIBRARY_PATH=/tmp/duckdb15 prove -lv t/60-quack.t

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

# -- a second server with a token of its own: two remotes on one client
#    connection is what an unnamed, unscoped secret could not do (karr k32).
my $PORT_B = 9503;

my $srv_b_dbh = DBI->connect(
  'dbi:DuckDB:dbname=:memory:', '', '',
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 },
) or die "server B DBI connect failed: $DBI::errstr";

$srv_b_dbh->do('INSTALL quack');
$srv_b_dbh->do('LOAD quack');
$srv_b_dbh->do(q{
  CREATE TABLE hello (
    id   INTEGER PRIMARY KEY,
    s    VARCHAR NOT NULL
  )
});
$srv_b_dbh->do(q{INSERT INTO hello VALUES (1, 'hello from server B')});

my $quack_addr_b = "quack:localhost:$PORT_B";
eval {
  $srv_b_dbh->do("CALL quack_serve('$quack_addr_b', token => 'tokenB')");
};
if ($@) {
  $_->disconnect for $srv_b_dbh, $srv_dbh;
  plan skip_all => "quack_serve failed (port $PORT_B in use or other error): $@";
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

# ---- one secret per attach: named after the alias, scoped to the address
# (karr k32). Raw $dbh and selectall_arrayref throughout, as above.
my $quack_secrets = sub {
  return {
    map { $_->[0] => $_->[1] } @{ $dbh->selectall_arrayref(
      q{SELECT name, scope FROM duckdb_secrets() WHERE type = 'quack'},
    ) }
  };
};
my $hello_from = sub {
  my ($alias) = @_;
  return eval {
    $dbh->selectall_arrayref("SELECT s FROM $alias.hello WHERE id = 1")->[0][0];
  } // "died: $@";
};

is_deeply $quack_secrets->(), {},
  'quack_detach dropped the secret quack_attach created for the alias';

# Two servers, two tokens, one connection.
eval { $storage->quack_attach($quack_addr, as => 'ra', token => 'testtoken') };
is $@, '', 'quack_attach with a token works a second time on the same connection';
eval { $storage->quack_attach($quack_addr_b, as => 'rb', token => 'tokenB') };
is $@, '', 'a second server with a different token attaches beside the first';

is $hello_from->('ra'), 'hello from server',   'alias ra answers from server A';
is $hello_from->('rb'), 'hello from server B', 'alias rb answers from server B';

is_deeply $quack_secrets->(),
  { dbio_quack_ra => [$quack_addr], dbio_quack_rb => [$quack_addr_b] },
  'each attach has its own secret, named after the alias and scoped to its address';

# Detach removes the secret of that alias and nothing else.
eval { $storage->quack_detach('ra') };
is $@, '', 'quack_detach of one of two remotes did not die';
is_deeply $quack_secrets->(), { dbio_quack_rb => [$quack_addr_b] },
  'quack_detach dropped the secret of its alias and left the other one';
is $hello_from->('rb'), 'hello from server B', 'the other remote still answers';

# No token is left in the room: server A is only reachable with one again,
# and B's token is not offered to it. An unscoped secret would be sent to A
# and die with "Authentication failed" instead.
eval { $storage->quack_attach($quack_addr, as => 'ra') };
like $@, qr/Could not find a Quack authentication token/,
  'without a token server A is unreachable once its secret is gone';
is_deeply $quack_secrets->(), { dbio_quack_rb => [$quack_addr_b] },
  'quack_attach without a token creates no secret';

# A secret the caller made is theirs: attach without a token uses it,
# detach leaves it alone.
$dbh->do("CREATE SECRET my_own (TYPE quack, TOKEN 'testtoken', SCOPE '$quack_addr')");
eval { $storage->quack_attach($quack_addr, as => 'ra') };
is $@, '', 'quack_attach without a token attaches through a caller-made secret';
eval { $storage->quack_detach('ra') };
is $@, '', 'quack_detach of an alias attached without a token did not die';
is_deeply $quack_secrets->(),
  { my_own => [$quack_addr], dbio_quack_rb => [$quack_addr_b] },
  'quack_detach leaves a secret it did not create';
$dbh->do('DROP SECRET my_own');

# Detach + re-attach of the same alias with a token (the rotation path).
eval { $storage->quack_attach($quack_addr, as => 'ra', token => 'testtoken') };
is $@, '', 'the same alias attaches again with a token after quack_detach';
is $hello_from->('ra'), 'hello from server', 'the re-attached alias answers from server A';

# A failed attach leaves the secret store as it found it. Two secrets with
# the same scope are not ambiguous to DuckDB -- the name that sorts first
# wins -- so a leftover dbio_quack_aaa_bad carrying the wrong token would
# beat the secret of any later alias for this address.
my $two_secrets = { dbio_quack_ra => [$quack_addr], dbio_quack_rb => [$quack_addr_b] };

eval { $storage->quack_attach($quack_addr, as => 'aaa_bad', token => 'wrong') };
like $@, qr/Authentication failed/, 'quack_attach with a wrong token dies with the engine error';
is_deeply $quack_secrets->(), $two_secrets, 'a rejected token leaves no secret behind';

eval { $storage->quack_attach($quack_addr, as => 'zzz_good', token => 'testtoken') };
is $@, '', 'the same address attaches under another alias after a failed attempt';
is $hello_from->('zzz_good'), 'hello from server', 'and that alias answers from server A';
eval { $storage->quack_detach('zzz_good') };
is $@, '', 'quack_detach of the extra alias did not die';

eval { $storage->quack_attach('quack:localhost:9502', as => 'dead', token => 'x') };
like $@, qr/Could not connect/, 'quack_attach to an address nobody serves dies';
is_deeply $quack_secrets->(), $two_secrets, 'an unreachable server leaves no secret behind';

# Re-attach of an alias that is still attached fails -- and must not cost
# the working remote its token.
eval { $storage->quack_attach($quack_addr, as => 'ra', token => 'wrong') };
isnt $@, '', 'quack_attach of an alias that is still attached dies';
is $hello_from->('ra'), 'hello from server', 'the attached remote still answers afterwards';
is_deeply $quack_secrets->(), $two_secrets, 'and its secret is still there';
$dbh->do('DETACH ra');
eval { $dbh->do("ATTACH '$quack_addr' AS ra") };
is $@, '', 'and still carries the token it was attached with';

eval { $storage->quack_detach($_) } for qw(ra rb);
is_deeply $quack_secrets->(), {}, 'no secret is left once every remote is detached';

# A failed DETACH still cleans up (karr k36): an alias that is not attached
# but whose secret exists throws the DETACH error and loses the secret.
$dbh->do("CREATE SECRET dbio_quack_ghost (TYPE quack, TOKEN 'x', SCOPE '$quack_addr')");
eval { $storage->quack_detach('ghost') };
like $@, qr/ghost/, 'quack_detach of an alias that is not attached throws the DETACH error';
is_deeply $quack_secrets->(), {}, 'and dropped the secret of that alias anyway';

# A DETACH in a transaction that rolls back: DuckDB restores the secret but
# not the attachment. The second quack_detach cannot detach, and cleans up.
eval { $storage->quack_attach($quack_addr, as => 'ra', token => 'testtoken') };
is $@, '', 'alias attached with a token for the rollback case';
eval { $storage->txn_do(sub { $storage->quack_detach('ra'); die "rollback\n" }) };
like $@, qr/rollback/, 'the transaction around quack_detach rolled back';
is_deeply $quack_secrets->(), { dbio_quack_ra => [$quack_addr] },
  'the rollback restored the secret although the catalog stays detached';
eval { $storage->quack_detach('ra') };
like $@, qr/ra/, 'a second quack_detach throws the DETACH error';
is_deeply $quack_secrets->(), {}, 'and has dropped the restored secret';

# quack_detach is documented for any catalog: it must work on a connection
# that never loaded quack, where no such secret can exist.
{
  my $plain = DBIO::DuckDB::Test->init_schema(no_populate => 1, no_deploy => 1);
  my $plain_dbh = $plain->storage->dbh;
  $plain_dbh->do(q{ATTACH ':memory:' AS localcat});

  eval { $plain->storage->quack_detach('localcat') };
  is $@, '', 'quack_detach of a non-quack catalog did not die';

  my $ext = $plain_dbh->selectall_arrayref(
    q{SELECT extension_name, loaded FROM duckdb_extensions() WHERE extension_name = 'quack'},
  )->[0];
  ok $ext && !$ext->[1], 'quack is known but was never loaded on that connection';

  my $left = $plain_dbh->selectall_arrayref(
    q{SELECT count(*) FROM duckdb_databases() WHERE database_name = 'localcat'},
  )->[0][0];
  is $left, 0, 'and the catalog is detached';

  $plain->storage->disconnect;
}

# connect_call_quack_attach with a token: the secret and the ATTACH are one
# transaction, and that has to work from inside the connect actions too.
{
  my $hooked = DBIO::DuckDB::Test->init_schema(
    no_populate     => 1,
    no_deploy       => 1,
    on_connect_call => [[ quack_attach => {
      addr => $quack_addr_b, as => 'hooked', token => 'tokenB',
    } ]],
  );
  my $hooked_dbh = eval { $hooked->storage->dbh };
  is $@, '', 'connect with a quack_attach on-connect hook carrying a token did not die';
  is $hooked_dbh->selectall_arrayref('SELECT s FROM hooked.hello WHERE id = 1')->[0][0],
    'hello from server B', 'the hooked alias answers from server B';

  $hooked->storage->disconnect;
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

$srv_b_dbh->disconnect;
$srv_dbh->disconnect;

done_testing;
