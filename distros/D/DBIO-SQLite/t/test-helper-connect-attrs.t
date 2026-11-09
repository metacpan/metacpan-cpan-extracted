use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test;

# karr k76: init_schema arguments that steer the test helper are not connect
# attributes. The storage rejects connect attributes it does not know, so the
# helper must keep them out of the attribute hash it hands to connect().

local $ENV{DBIO_TEST_DSN};

my @helper = qw(
  no_deploy no_populate no_connect storage_type sqlite_use_file
  compose_connection replicated deploy_args replicant_connect_info
);

my ($dsn, $user, $pass, $attrs) = DBIO::SQLite::Test->_database(
  (map { $_ => 1 } @helper),
  quote_names => 1,
  auto_savepoint => 1,
);

is ref $attrs, 'HASH', '_database returns an attribute hash';
ok !exists $attrs->{$_}, "helper argument $_ is not a connect attribute"
  for @helper;
ok $attrs->{quote_names}, 'quote_names goes through';
ok $attrs->{auto_savepoint}, 'auto_savepoint goes through';
is $attrs->{AutoCommit}, 1, 'AutoCommit default kept';
like $dsn, qr/DBIOTest-\d+\.db$/, 'sqlite_use_file still picks the db file';

{
  my (undef, undef, undef, $plain) = DBIO::SQLite::Test->_database;
  is ref $plain, 'HASH', '_database without arguments still works';
}

{
  my $schema = DBIO::SQLite::Test->init_schema(
    no_populate => 1,
    quote_names => 1,
  );
  ok $schema->storage->dbh, 'init_schema(no_populate, quote_names) connects';
  ok $schema->storage->sql_maker->quote_char, 'quote_names took effect';
}

done_testing;
