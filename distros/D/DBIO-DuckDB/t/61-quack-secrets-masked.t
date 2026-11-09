#!/usr/bin/env perl
# t/61-quack-secrets-masked.t -- karr k42: what quack_attach throws does not
# carry the token or a password in the address.
#
# DuckDB's error text for a failed statement quotes the whole SQL, and
# quack_attach's CREATE SECRET statement holds the token. A NUL in the token
# makes that statement fail to parse -- the parser's message then repeats it.
# The address in "got: ..." of the scheme check can be a URI with a password.
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

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::DuckDB::Storage');
my $storage = $schema->connect('dbi:DuckDB:dbname=:memory:')->storage;

my $err = sub {
  my $code = shift;
  eval { $code->(); 1 } and return '';
  return "$@";
};

my $e = $err->(sub {
  $storage->quack_attach("quack:127.0.0.1:1", as => 'r', token => "a\0tokensekret");
});
like $e, qr/Parser Error|CREATE OR REPLACE SECRET/,
  'the failing statement is the CREATE SECRET one (the probe is valid)';
unlike $e, qr/tokensekret/, 'the token is not in the message of a failed CREATE SECRET';

$e = $err->(sub {
  $storage->quack_attach('https://user:addrsekret@host/x', as => 'r');
});
like $e, qr/must start with 'quack:'/, 'a non-quack address is refused';
unlike $e, qr/addrsekret/, 'the password of the address is not in the message';

done_testing;
