#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use 5.010;
use strict;
use warnings;

use App::reposdb;
use Test::More 0.98;
use Test::SQL::Schema::Versioned;
use Test::WithDB::SQLite;

sql_schema_spec_ok(
    $App::reposdb::db_schema_spec,
    Test::WithDB::SQLite->new,
);
done_testing;
