#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}


use 5.010;
use strict;
use warnings;

use App::rimetadb;
use Test::More 0.98;
use Test::SQL::Schema::Versioned;
use Test::WithDB::SQLite;

sql_schema_spec_ok(
    $App::rimetadb::db_schema_spec,
    Test::WithDB::SQLite->new,
);
done_testing;
