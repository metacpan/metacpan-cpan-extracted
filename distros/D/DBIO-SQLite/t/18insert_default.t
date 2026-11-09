use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();
$schema->storage->sql_maker->quote_char('"');

my $rs = $schema->resultset ('Artist');
my $last_obj = $rs->search ({}, { order_by => { -desc => 'artistid' }, rows => 1})->single;
my $last_id = $last_obj ? $last_obj->artistid : 0;

my $obj;

# On libsqlite 3.35+ the driver declares insert_returning, so the autoinc PK is
# fetched straight off the INSERT instead of via last_insert_id afterwards.
my $expected_insert_sql = 'INSERT INTO "artist" DEFAULT VALUES'
  . ( $schema->storage->_use_insert_returning ? ' RETURNING "artistid"' : '' );

$schema->is_executed_sql_bind( sub {
  $obj = $rs->create ({})
}, [[
  $expected_insert_sql
]], 'Default-value insert correct SQL' );

ok ($obj, 'Insert defaults ( $rs->create ({}) )' );

# this should be picked up without calling the DB again
is ($obj->artistid, $last_id + 1, 'Autoinc PK works');

# for this we need to refresh
$obj->discard_changes;
is ($obj->rank, 13, 'Default value works');

done_testing;
