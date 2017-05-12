#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;

BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 63;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @AvailableDrivers ) {
SKIP: {
	unless( has_schema( 'TestApp', $d ) ) {
		skip "No schema for '$d' driver", TESTS_PER_DRIVER;
	}
	unless( should_test( $d ) ) {
		skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
	}

	my $handle = get_handle( $d );
	connect_handle( $handle );
	isa_ok($handle->dbh, 'DBI::db', "Got handle for $d");

	my $ret = init_schema( 'TestApp', $handle );
	isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back");

	my $emp = TestApp::Employee->new($handle);
	my $e_id = $emp->Create( Name => 'RUZ' );
	ok($e_id, "Got an id for the new employee: $e_id");
	$emp->Load($e_id);
	is($emp->id, $e_id);
	
	my $phone_collection = $emp->Phones;
	isa_ok($phone_collection, 'TestApp::PhoneCollection');
	
	{
	    my $ph = $phone_collection->Next;
	    is($ph, undef, "No phones yet");
	}
	
	my $phone = TestApp::Phone->new($handle);
	isa_ok( $phone, 'TestApp::Phone');
	my $p_id = $phone->Create( Employee => $e_id, Phone => '+7(903)264-03-51');
	is($p_id, 1, "Loaded phone $p_id");
	$phone->Load( $p_id );

	my $obj = $phone->Employee;

	ok($obj, "Employee #$e_id has phone #$p_id");
	isa_ok( $obj, 'TestApp::Employee');
	is($obj->id, $e_id);
	is($obj->Name, 'RUZ');
	
	{
	    $phone_collection->RedoSearch;
	    my $ph = $phone_collection->Next;
	    isa_ok($ph, 'TestApp::Phone');
	    is($ph->id, $p_id, 'found first phone');
	    is($ph->Phone, '+7(903)264-03-51');
	    is($phone_collection->Next, undef);
	}

	# tests for no object mapping
	my $val = $phone->Phone;
	is( $val, '+7(903)264-03-51', 'Non-object things still work');
	
	my $emp2 = TestApp::Employee->new($handle);
	isa_ok($emp2, 'TestApp::Employee');
	my $e2_id = $emp2->Create( Name => 'Dave' );
	ok($e2_id, "Got an id for the new employee: $e2_id");
	$emp2->Load($e2_id);
	is($emp2->id, $e2_id);

	my $phone2_collection = $emp2->Phones;
	isa_ok($phone2_collection, 'TestApp::PhoneCollection');

	{
	    my $ph = $phone2_collection->Next;
	    is($ph, undef, "new emp has no phones");
	}
	
	{
	    $phone_collection->RedoSearch;
	    my $ph = $phone_collection->Next;
	    isa_ok($ph, 'TestApp::Phone');
	    is($ph->id, $p_id, 'first emp still has phone');
	    is($ph->Phone, '+7(903)264-03-51');
	    is($phone_collection->Next, undef);
	}

	$phone->SetEmployee($e2_id);
	
		
	my $emp3 = $phone->Employee;
	isa_ok($emp3, 'TestApp::Employee');
	is($emp3->Name, 'Dave', 'changed employees by ID');
	is($emp3->id, $emp2->id);

	{
	    $phone_collection->RedoSearch;
	    is($phone_collection->Next, undef, "first emp lost phone");
	}

	{
	    $phone2_collection->RedoSearch;
	    my $ph = $phone2_collection->Next;
	    isa_ok($ph, 'TestApp::Phone');
	    is($ph->id, $p_id, 'new emp stole the phone');
	    is($ph->Phone, '+7(903)264-03-51');
	    is($phone2_collection->Next, undef);
	}


	$phone->SetEmployee($emp);

	my $emp4 = $phone->Employee;
	isa_ok($emp4, 'TestApp::Employee');
	is($emp4->Name, 'RUZ', 'changed employees by obj');
	is($emp4->id, $emp->id);

	{
	    $phone2_collection->RedoSearch;
	    is($phone2_collection->Next, undef, "second emp lost phone");
	}

	{
	    $phone_collection->RedoSearch;
	    my $ph = $phone_collection->Next;
	    isa_ok($ph, 'TestApp::Phone');
	    is($ph->id, $p_id, 'first emp stole the phone');
	    is($ph->Phone, '+7(903)264-03-51');
	    is($phone_collection->Next, undef);
	}
	
	my $phone2 = TestApp::Phone->new($handle);
	isa_ok( $phone2, 'TestApp::Phone');
	my $p2_id = $phone2->Create( Employee => $e_id, Phone => '123456');
	ok($p2_id, "Loaded phone $p2_id");
	$phone2->Load( $p2_id );
	
	{
	    $phone_collection->RedoSearch;
	    my $ph = $phone_collection->Next;
	    isa_ok($ph, 'TestApp::Phone');
	    is($ph->id, $p_id, 'still has this phone');
	    is($ph->Phone, '+7(903)264-03-51');
	    $ph = $phone_collection->Next;
	    isa_ok($ph, 'TestApp::Phone');
	    is($ph->id, $p2_id, 'now has that phone');
	    is($ph->Phone, '123456');
	    is($phone_collection->Next, undef);
	}
	
	# Test Create with obj as argument
	my $phone3 = TestApp::Phone->new($handle);
	isa_ok( $phone3, 'TestApp::Phone');
	my $p3_id = $phone3->Create( Employee => $emp, Phone => '7890');
	ok($p3_id, "Loaded phone $p3_id");
	$phone3->Load( $p3_id );
	
	{
	    $phone_collection->RedoSearch;
	    my $ph = $phone_collection->Next;
	    isa_ok($ph, 'TestApp::Phone');
	    is($ph->id, $p_id, 'still has this phone');
	    is($ph->Phone, '+7(903)264-03-51');
	    $ph = $phone_collection->Next;
	    isa_ok($ph, 'TestApp::Phone');
	    is($ph->id, $p2_id, 'still has that phone');
	    is($ph->Phone, '123456');
	    $ph = $phone_collection->Next;
	    isa_ok($ph, 'TestApp::Phone');
	    is($ph->id, $p3_id, 'even has this other phone');
	    is($ph->Phone, '7890');
	    is($phone_collection->Next, undef);
	}
	
	

	cleanup_schema( 'TestApp', $handle );
}} # SKIP, foreach blocks

1;


package TestApp;
sub schema_sqlite {
[
q{
CREATE TABLE Employees (
	id integer primary key,
	Name varchar(36)
)
}, q{
CREATE TABLE Phones (
	id integer primary key,
	Employee integer NOT NULL,
	Phone varchar(18)
) }
]
}

sub schema_mysql {
[ q{
CREATE TEMPORARY TABLE Employees (
	id integer AUTO_INCREMENT primary key,
	Name varchar(36)
)
}, q{
CREATE TEMPORARY TABLE Phones (
	id integer AUTO_INCREMENT primary key,
	Employee integer NOT NULL,
	Phone varchar(18)
)
} ]
}

sub schema_pg {
[ q{
CREATE TEMPORARY TABLE Employees (
	id serial PRIMARY KEY,
	Name varchar
)
}, q{
CREATE TEMPORARY TABLE Phones (
	id serial PRIMARY KEY,
	Employee integer references Employees(id),
	Phone varchar
)
} ]
}

package TestApp::Employee;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub Table { 'Employees' }

sub Schema {
    return {
        Name => { TYPE => 'varchar' },
        Phones => { REFERENCES => 'TestApp::PhoneCollection', KEY => 'Employee' }
    };
}

sub _Value  {
  my $self = shift;
  my $x =  ($self->__Value(@_));
  return $x;
}


1;

package TestApp::Phone;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub Table { 'Phones' }

sub Schema {
    return {   
        Employee => { REFERENCES => 'TestApp::Employee' },
        Phone => { TYPE => 'varchar' }, 
    }
}

package TestApp::PhoneCollection;

use base qw/DBIx::SearchBuilder/;

sub Table {
    my $self = shift;
    my $tab = $self->NewItem->Table();
    return $tab;
}

sub NewItem {
    my $self = shift;
    my $class = 'TestApp::Phone';
    return $class->new( $self->_Handle );

}


1;
