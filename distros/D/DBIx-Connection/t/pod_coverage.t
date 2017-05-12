use strict;
use warnings;

use Test::Pod::Coverage tests =>  10;

pod_coverage_ok('DBIx::Connection', "should have coverage lib::DBIx::Connection POD file");
pod_coverage_ok('DBIx::QueryCursor', "should have coverage lib::DBIx::QueryCursor POD file");
pod_coverage_ok('DBIx::PLSQLHandler', "should have coverage lib::DBIx::PLSQLHandler POD file");
pod_coverage_ok('DBIx::SQLHandler', "should have coverage lib::DBIx::SQLHandler POD file");
pod_coverage_ok('DBIx::Connection::PostgreSQL::SQL', "should have coverage lib::DBIx::Connection::PosteerSQL::SQL POD file");
pod_coverage_ok('DBIx::Connection::PostgreSQL::PLSQL', "should have coverage lib::DBIx::Connection::PostgreSQL::PLSQL POD file");
pod_coverage_ok('DBIx::Connection::Oracle::SQL', "should have coverage lib::DBIx::Connection::Oracle::SQL POD file");
pod_coverage_ok('DBIx::Connection::Oracle::PLSQL', "should have coverage lib::DBIx::Connection::Oracle::PLSQL POD file");
pod_coverage_ok('DBIx::Connection::MySQL::SQL', "should have coverage lib::DBIx::Connection::MySQL::SQL POD file");
pod_coverage_ok('DBIx::Connection::MySQL::PLSQL', "should have coverage lib::DBIx::Connection::MySQL::PLSQL POD file");