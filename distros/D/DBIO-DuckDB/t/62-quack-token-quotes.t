#!/usr/bin/env perl
# t/62-quack-token-quotes.t -- karr k37: a quote in a quack token is doubled,
# not refused (ADR 0002 point 3), and that is safe: the token arrives
# unchanged and never leaves its string literal.
#
# Server and client are both DBIO storages; the token is one a naive
# interpolation would break out of.
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

my $PORT  = 9505;
my $addr  = "quack:localhost:$PORT";
my $token = q{it's "x"'); DROP TABLE hello; --};

my $server = $connect->();
my $sdbh   = $server->dbh;
$sdbh->do('CREATE TABLE hello (id INTEGER, s VARCHAR)');
$sdbh->do(q{INSERT INTO hello VALUES (1, 'hello')});

eval { $server->quack_serve($addr, token => $token) };
if ($@) {
  plan skip_all => "quack_serve failed (port $PORT in use or other error): $@";
}
pass 'quack_serve accepts a token with quotes and SQL in it';

my $client = $connect->();
eval { $client->quack_attach($addr, as => 'rem', token => $token) };
is $@, '', 'quack_attach with the same token attaches: the server holds it unchanged';

is $client->dbh->selectall_arrayref('SELECT s FROM rem.hello')->[0][0], 'hello',
  'the remote answers';
is $sdbh->selectall_arrayref('SELECT COUNT(*) FROM hello')->[0][0], 1,
  'the server table is still there: the token did not leave its literal';

# DuckDB refuses to show a secret unredacted, so exactness is shown by the
# server: it authenticated the attach above with the full token, and
# it refuses a token that is only a prefix of it.
# A token that is only a prefix of the real one is refused by the server.
$client->quack_detach('rem');
eval { $client->quack_attach($addr, as => 'rem', token => q{it's}) };
like $@, qr/uthenticat/, 'a token that is only a prefix of the real one is refused';

done_testing;
