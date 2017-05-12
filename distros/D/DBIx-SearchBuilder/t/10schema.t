#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use constant TESTS_PER_DRIVER => 14;
our @AvailableDrivers;

BEGIN {
  require("t/utils.pl");
  my $total = 3 + scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
  if( not eval { require DBIx::DBSchema } ) {
    plan skip_all => "DBIx::DBSchema not installed";
  } else {
    plan tests => $total;
  }
}

BEGIN { 
  use_ok("DBIx::SearchBuilder::SchemaGenerator");
  use_ok("DBIx::SearchBuilder::Handle");
}

require_ok("t/testmodels.pl");

foreach my $d ( @AvailableDrivers ) {
  SKIP: {
    unless ($d eq 'Pg') {
      skip "first goal is to work on Pg", TESTS_PER_DRIVER;
    }
    
    unless( should_test( $d ) ) {
    	skip "ENV is not defined for driver $d", TESTS_PER_DRIVER;
    }
  
    my $handle = get_handle( $d );
    connect_handle( $handle );
    isa_ok($handle, "DBIx::SearchBuilder::Handle::$d");
    isa_ok($handle->dbh, 'DBI::db');

    my $SG = DBIx::SearchBuilder::SchemaGenerator->new($handle);

    isa_ok($SG, 'DBIx::SearchBuilder::SchemaGenerator');

    isa_ok($SG->_db_schema, 'DBIx::DBSchema');

    is($SG->CreateTableSQLText, '', "no tables means no sql");

    my $ret = $SG->AddModel('Sample::This::Does::Not::Exist');

    ok($ret == 0, "couldn't add model from nonexistent class");

    like($ret->error_message, qr/Error making new object from Sample::This::Does::Not::Exist/, 
      "couldn't add model from nonexistent class");

    is($SG->CreateTableSQLText, '', "no tables means no sql");

    $ret = $SG->AddModel('Sample::Address');

    ok($ret != 0, "added model from real class");

    is_ignoring_space($SG->CreateTableSQLText, <<END_SCHEMA, "got the right schema");
    CREATE TABLE Addresses ( 
      id serial NOT NULL , 
      EmployeeId integer ,
      Name varchar DEFAULT 'Frank' ,
      Phone varchar ,
      PRIMARY KEY (id)
    ) ;
END_SCHEMA

    my $employee = Sample::Employee->new;
    
    isa_ok($employee, 'Sample::Employee');
    
    $ret = $SG->AddModel($employee);

    ok($ret != 0, "added model from an instantiated object");

    is_ignoring_space($SG->CreateTableSQLText, <<END_SCHEMA, "got the right schema");
    CREATE TABLE Addresses ( 
      id serial NOT NULL , 
      EmployeeId integer  ,
      Name varchar DEFAULT 'Frank' ,
      Phone varchar ,
      PRIMARY KEY (id)
    ) ;
    CREATE TABLE Employees (
      id serial NOT NULL ,
      Dexterity integer ,
      Name varchar ,
      PRIMARY KEY (id)
    ) ;
END_SCHEMA
    
    my $manually_make_text = join ' ', map { "$_;" } $SG->CreateTableSQLStatements;
    is_ignoring_space($SG->CreateTableSQLText, $manually_make_text, 'CreateTableSQLText is the statements in CreateTableSQLStatements')
}}

sub is_ignoring_space {
  my $a = shift;
  my $b = shift;
  
  $a =~ s/^\s+//; $a =~ s/\s+$//; $a =~ s/\s+/ /g;
  $b =~ s/^\s+//; $b =~ s/\s+$//; $b =~ s/\s+/ /g;
  
  unshift @_, $b; unshift @_, $a;
  
  goto &is;
}
