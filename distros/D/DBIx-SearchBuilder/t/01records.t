#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;
BEGIN { require "./t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 66;

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

# Handle->Fields
        is_deeply(
            [$handle->Fields('Address')],
            [qw(id name phone employeeid)],
            "listed all columns in the table"
        );
        is_deeply(
            [$handle->Fields('Some')],
            [],
            "no table -> no fields"
        );

# _Accessible testings
	is( $rec->_Accessible('id' => 'read'), 1, 'id is accessible for read' );
	is( $rec->_Accessible('id' => 'write'), undef, 'id is not accessible for write' );
	is( $rec->_Accessible('id'), undef, "any field is not accessible in undefined mode" );
	is( $rec->_Accessible('unexpected_field' => 'read'), undef, "field doesn't exist and can't be accessible for read" );
	is_deeply( [sort($rec->ReadableAttributes)], [qw(EmployeeId Name Phone id)], 'readable attributes' );
	is_deeply( [sort($rec->WritableAttributes)], [qw(EmployeeId Name Phone)], 'writable attributes' );

	can_ok($rec,'Create');

	my ($id) = $rec->Create( Name => 'Jesse', Phone => '617 124 567');
	ok($id,"Created record ". $id);
	ok($rec->Load($id), "Loaded the record");


	is($rec->id, $id, "The record has its id");
	is ($rec->Name, 'Jesse', "The record's name is Jesse");

	my ($val, $msg) = $rec->SetName('Obra');
	ok($val, $msg) ;
	is($rec->Name, 'Obra', "We did actually change the name");

# Validate immutability of the field id
	($val, $msg) = $rec->Setid( $rec->id + 1 );
	ok(!$val, $msg);
	is($msg, 'Immutable field', 'id is immutable field');
	is($rec->id, $id, "The record still has its id");

# Check some non existant field
	ok( !eval{ $rec->SomeUnexpectedField }, "The record has no 'SomeUnexpectedField'");
	{
		# test produce DBI warning
		local $SIG{__WARN__} = sub {return};
		is( $rec->_Value( 'SomeUnexpectedField' ), undef, "The record has no 'SomeUnexpectedField'");
	}
	($val, $msg) = $rec->SetSomeUnexpectedField( 'foo' );
	ok(!$val, $msg);
	is($msg, 'Nonexistant field?', "Field doesn't exist");
	($val, $msg) = $rec->_Set('SomeUnexpectedField', 'foo');
	ok(!$val, "$msg");


# Validate truncation on update

	($val,$msg) = $rec->SetName('1234567890123456789012345678901234567890');
	ok($val, $msg);
	is($rec->Name, '12345678901234', "Truncated on update");
	$val = $rec->TruncateValue(Phone => '12345678901234567890');
	is($val, '123456789012345678', 'truncate by length attribute');


# Test unicode truncation:
	my $univalue = "這是個測試";
	($val,$msg) = $rec->SetName($univalue.$univalue);
	ok($val, $msg) ;
	is($rec->Name, '這是個測');



# make sure we do _not_ truncate things which should not be truncated
	($val,$msg) = $rec->SetEmployeeId('1234567890');
	ok($val, $msg) ;
	is($rec->EmployeeId, '1234567890', "Did not truncate id on create");

# make sure we do truncation on create
	my $newrec = TestApp::Address->new($handle);
	my $newid = $newrec->Create( Name => '1234567890123456789012345678901234567890',
	                             EmployeeId => '1234567890' );

	$newrec->Load($newid);

	ok ($newid, "Created a new record");
	is($newrec->Name, '12345678901234', "Truncated on create");
	is($newrec->EmployeeId, '1234567890', "Did not truncate id on create");

# no prefetch feature and _LoadFromSQL sub checks
	$newrec = TestApp::Address->new($handle);
	($val, $msg) = $newrec->_LoadFromSQL('SELECT id FROM Address WHERE id = ?', $newid);
	is($val, 1, 'found object');
	is($newrec->Name, '12345678901234', "autoloaded not prefetched field");
	is($newrec->EmployeeId, '1234567890', "autoloaded not prefetched field");

# _LoadFromSQL and missing PK
	$newrec = TestApp::Address->new($handle);
	($val, $msg) = $newrec->_LoadFromSQL('SELECT Name FROM Address WHERE Name = ?', '12345678901234');
	is($val, 0, "didn't find object");
	is($msg, "Missing a primary key?", "reason is missing PK");

# _LoadFromSQL and not existant row
	$newrec = TestApp::Address->new($handle);
	($val, $msg) = $newrec->_LoadFromSQL('SELECT id FROM Address WHERE id = ?', 0);
	is($val, 0, "didn't find object");
	is($msg, "Couldn't find row", "reason is wrong id");

# _LoadFromSQL and wrong SQL
	$newrec = TestApp::Address->new($handle);
	{
		local $SIG{__WARN__} = sub{return};
		($val, $msg) = $newrec->_LoadFromSQL('SELECT ...');
	}
	is($val, 0, "didn't find object");
	like($msg, qr/^Couldn't execute query/, "reason is bad SQL");

# test Load* methods
	$newrec = TestApp::Address->new($handle);
	$newrec->Load();
	is( $newrec->id, undef, "can't load record with undef id");

	$newrec = TestApp::Address->new($handle);
	$newrec->LoadByCol( Name => '12345678901234' );
	is( $newrec->id, $newid, "load record by 'Name' column value");

# LoadByCol with operator
	$newrec = TestApp::Address->new($handle);
	$newrec->LoadByCol( Name => { value => '%45678%',
				      operator => 'LIKE' } );
	is( $newrec->id, $newid, "load record by 'Name' with LIKE");

# LoadByPrimaryKeys
	$newrec = TestApp::Address->new($handle);
	($val, $msg) = $newrec->LoadByPrimaryKeys( id => $newid );
	ok( $val, "load record by PK");
	is( $newrec->id, $newid, "loaded correct record");
	$newrec = TestApp::Address->new($handle);
	($val, $msg) = $newrec->LoadByPrimaryKeys( {id => $newid} );
	ok( $val, "load record by PK");
	is( $newrec->id, $newid, "loaded correct record" );
	$newrec = TestApp::Address->new($handle);
	($val, $msg) = $newrec->LoadByPrimaryKeys( Phone => 'some' );
	ok( !$val, "couldn't load, missing PK field");
	is( $msg, "Missing PK field: 'id'", "right error message" );

# LoadByCols and empty or NULL values
	$rec = TestApp::Address->new($handle);
	$id = $rec->Create( Name => 'Obra', Phone => undef );
	ok( $id, "new record");
	$rec = TestApp::Address->new($handle);
	$rec->LoadByCols( Name => 'Obra', Phone => undef, EmployeeId => '' );
    is( $rec->id, $id, "loaded record by empty value" );

# __Set error paths
	$rec = TestApp::Address->new($handle);
	$rec->Load( $id );
	$val = $rec->SetName( 'Obra' );
	isa_ok( $val, 'Class::ReturnValue', "couldn't set same value, error returned");
	is( ($val->as_array)[1], "That is already the current value", "correct error message" );
	is( $rec->Name, 'Obra', "old value is still there");
	$val = $rec->SetName( 'invalid' );
	isa_ok( $val, 'Class::ReturnValue', "couldn't set invalid value, error returned");
	is( ($val->as_array)[1], 'Illegal value for Name', "correct error message" );
	is( $rec->Name, 'Obra', "old value is still there");
	( $val, $msg ) = $rec->SetName();
    ok( $val, $msg );
	is( $rec->Name, undef, "no value means null");

# deletes
	$newrec = TestApp::Address->new($handle);
	$newrec->Load( $newid );
	is( $newrec->Delete, 1, 'successfuly delete record');
	$newrec = TestApp::Address->new($handle);
	$newrec->Load( $newid );
	is( $newrec->id, undef, "record doesn't exist any more");

	cleanup_schema( 'TestApp::Address', $handle );
}} # SKIP, foreach blocks

1;



package TestApp::Address;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('Address');
    $self->_Handle($handle);
}

sub ValidateName
{
	my ($self, $value) = @_;
    return 1 unless defined $value;
	return 0 if $value =~ /invalid/i;
	return 1;
}

sub _ClassAccessible {

    {   
        
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
