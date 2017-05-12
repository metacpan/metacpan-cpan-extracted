#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 16;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @AvailableDrivers ) {
SKIP: {
	unless( has_schema( 'TestApp::Address', $d ) ) {
		skip "No schema for '$d' driver", TESTS_PER_DRIVER;
	}
	unless( should_test( $d ) ) {
		skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
	}

	my $handle = get_handle( $d );
	connect_handle( $handle );
	isa_ok($handle->dbh, 'DBI::db');

	my $ret = init_schema( 'TestApp::Address', $handle );
	isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back");

	my $rec = TestApp::Address->new($handle);
	isa_ok($rec, 'DBIx::SearchBuilder::Record');

	my ($id) = $rec->Create( Name => 'Jesse', Phone => '617 124 567');
	ok($id,"Created record #$id");

	ok($rec->Load($id), "Loaded the record");
	is($rec->id, $id, "The record has its id");
	is($rec->Name, 'Jesse', "The record's name is Jesse");

    my $rec_cache = TestApp::Address->new($handle);
    my ($status, $msg) = $rec_cache->LoadById($id);
    ok($status, 'loaded record');
    is($rec_cache->id, $id, 'the same record as we created');
    is($msg, 'Fetched from cache', 'we fetched record from cache');

    DBIx::SearchBuilder::Record::Cachable->FlushCache;

	ok($rec->LoadByCols( Name => 'Jesse' ), "Loaded the record");
	is($rec->id, $id, "The record has its id");
	is($rec->Name, 'Jesse', "The record's name is Jesse");

    $rec_cache = TestApp::Address->new($handle);
    ($status, $msg) = $rec_cache->LoadById($id);
    ok($status, 'loaded record');
    is($rec_cache->id, $id, 'the same record as we created');
    is($msg, 'Fetched from cache', 'we fetched record from cache');

	cleanup_schema( 'TestApp::Address', $handle );
}} # SKIP, foreach blocks

1;



package TestApp::Address;

use base qw/DBIx::SearchBuilder::Record::Cachable/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('Address');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    return {
        id =>
        {read => 1, type => 'int(11)', default => ''}, 
        Name => 
        {read => 1, write => 1, type => 'varchar(14)', default => ''},
        Phone => 
        {read => 1, write => 1, type => 'varchar(18)', length => 18, default => ''},
        EmployeeId => 
        {read => 1, write => 1, type => 'int(8)', default => ''},

    }
}

sub _CacheConfig {
    return {
        'cache_for_sec' => 60,
    };
}

sub schema_mysql {
<<EOF;
CREATE TEMPORARY TABLE Address (
        id integer AUTO_INCREMENT,
        Name varchar(36),
        Phone varchar(18),
        EmployeeId int(8),
  	PRIMARY KEY (id))
EOF

}

sub schema_pg {
<<EOF;
CREATE TEMPORARY TABLE Address (
        id serial PRIMARY KEY,
        Name varchar,
        Phone varchar,
        EmployeeId integer
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE TABLE Address (
        id  integer primary key,
        Name varchar(36),
        Phone varchar(18),
        EmployeeId int(8))
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE Address_seq",
    "CREATE TABLE Address (
        id integer CONSTRAINT Address_Key PRIMARY KEY,
        Name varchar(36),
        Phone varchar(18),
        EmployeeId integer
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE Address_seq",
    "DROP TABLE Address", 
] }

1;
