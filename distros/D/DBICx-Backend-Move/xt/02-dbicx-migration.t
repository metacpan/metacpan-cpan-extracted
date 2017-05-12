#!perl

use strict;
use warnings;
no warnings 'uninitialized'; # I would use common::sense but I don't want to increase the requirement list :-)

use Test::More;
use lib 't/lib';

use DBICx::Migration::Test::Schema::TestTools;
my $error = DBICx::Migration::Test::Schema::TestTools::setup_db('t/fixtures/testdb.yml', 'dbi:SQLite:dbname=t/from.sqlite');
die $error if $error;


use_ok('DBICx::Migration::Psql');

my $connect_from = [ 'dbi:mysql:dbname=testrundb_test;mysql_use_result=1', 'tapper', '' ];
my $connect_to   = [ 'dbi:Pg:dbname=testrundb_dev'  , 'hmai', '' ];
my $schema       = 'Tapper::Schema::TestrunDB';

my $migrator = DBICx::Migration::Psql->new();
my $retval = $migrator->migrate($connect_from, $connect_to, $schema, 1);
is($retval, 0, 'Migrated database');


done_testing();
