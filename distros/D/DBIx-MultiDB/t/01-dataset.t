#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);

system("sh $Bin/init_db.sh");

use DBI;
use Data::Dumper;
use Test::More;
use Test::Deep;

# this is a meta-test: make sure our test database is properly set

my @tests = (
	{
		dsn   => 'dbi:SQLite:dbname=/tmp/db1.db', 
		query => 'SELECT * FROM employee', 
		key   => 'id',
		expected_result => {
          '6' => {
                   'company_id' => '3',
                   'name' => 'c2',
                   'id' => '6'
                 },
          '4' => {
                   'company_id' => '2',
                   'name' => 'b2',
                   'id' => '4'
                 },
          '1' => {
                   'company_id' => '1',
                   'name' => 'a1',
                   'id' => '1'
                 },
          '3' => {
                   'company_id' => '2',
                   'name' => 'b1',
                   'id' => '3'
                 },
          '2' => {
                   'company_id' => '1',
                   'name' => 'a2',
                   'id' => '2'
                 },
          '5' => {
                   'company_id' => '3',
                   'name' => 'c1',
                   'id' => '5'
                 }
        },
	},
	{
		dsn   => 'dbi:SQLite:dbname=/tmp/db2.db', 
		query => 'SELECT * FROM company', 
		key   => 'id',
		expected_result => {
          '1' => {
                   'name' => 'a',
                   'id' => '1'
                 },
          '3' => {
                   'name' => 'c',
                   'id' => '3'
                 },
          '2' => {
                   'name' => 'b',
                   'id' => '2'
                 }
        },
	},
);

plan tests => scalar @tests;

for my $test (@tests) {
	my $dbh    = DBI->connect($test->{dsn});
	my $result = $dbh->selectall_hashref( $test->{query}, $test->{key} );

	cmp_deeply( $result, $test->{expected_result} )
		or print Dumper $result;
}
