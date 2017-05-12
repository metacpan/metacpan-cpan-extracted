#!/usr/bin/perl

# Formal testing for Business::AU::ABN

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 201;

# Check their perl version
BEGIN {
	ok( $] >= 5.005, "Your perl is new enough" );

	# Does the module load
	use_ok( 'Business::AU::ABN' );
	eval "use Business::AU::ABN 'validate_abn';";
	ok( ! $@, 'No error when importing' );
}





# Some checks we don't catch below
is( Business::AU::ABN->new, '', 'Bad ->new call returns as expected' );
is( Business::AU::ABN->new( undef ), '', 'Bad ->new call returns as expected' );
is( Business::AU::ABN->new( '' ), '', 'Bad ->new call returns as expected' );
is( Business::AU::ABN->new( ' ' ), '', 'Bad ->new call returns as expected' );





# Calls we expect to work
my @good = (
	# Known valid ABNs
	'31 103 572 158'   => '31 103 572 158',
	'12 004 044 937'   => '12 004 044 937',

	# Format variations
	'31103572158'      => '31 103 572 158',
	' 31 103 572 158 ' => '31 103 572 158',
	'31103572158001'   => '31 103 572 158 001',
	);
while ( @good ) {
	check_good( shift(@good), shift(@good) );
}

# Bad values, and the error messages we expect to get
my @bad = (
	undef             ,  'No value provided to check',   # Use , and not => otherwise undef becomes 'undef'
	''                => 'No value provided to check',
	' '               => 'No value provided to check',
	'a'               => 'ABN contains invalid characters',
	'1'               => 'ABNs are 11 digits, not 1',
	'12345678901234567890' => 'ABNs are 11 digits, not 20',
	'31 103 572 157'  => 'ABN looks correct, but fails checksum',
	'31 103 572 157 ' => 'ABN looks correct, but fails checksum',
	'31103572158000'  => 'Cannot have the group identifier 000',
	);
while ( @bad ) {
	check_bad( shift(@bad), shift(@bad) );
}





# Do a validation check in all four forms
sub check_good {
	my $value = shift;
	my $result = shift;
	my $message = defined $result ? "'$result'" : 'undef';

	# Check the full function form
	is( Business::AU::ABN::validate_abn( $value ), $result, "Full Function: $message" );
	is( Business::AU::ABN::errstr(), '', 'Error string is empty' );

	# Check the imported function form
	is( validate_abn( $value ), $result,                      "Imported Func: $message" );
	is( $Business::AU::ABN::errstr, '', 'Error string is empty' );

	# Check the static method form
	is( Business::AU::ABN->validate_abn( $value ), $result, "Class method: $message" );
	is( Business::AU::ABN->errstr, '', 'Error string is empty' );

	# Check the object method form
	my $ABN = Business::AU::ABN->new( $value );
	isa_ok( $ABN, 'Business::AU::ABN' );
	is( $ABN->validate_abn, $result, "Object method: $message" );
	is( $ABN->to_string, $result, 'Object to_string returns expected' );
	is( $ABN->errstr, '', 'Error string is empty' );
}

sub check_bad {
	my $value = shift;
	my $error = shift || '';
	my $message = "'$error'";

	# Check the full function form
	is( Business::AU::ABN::validate_abn( $value ), '', "Imported Func: $message" );
	is( $Business::AU::ABN::errstr, $error, "Imported Func: $message" );
	is( Business::AU::ABN->errstr, $error, "Imported Func: $message" );
	is( Business::AU::ABN::errstr(), $error, "Imported Func: $message" );

	# Check the imported function form
	is( validate_abn( $value ), '', "Full Function: $message" );
	is( $Business::AU::ABN::errstr, $error, "Full Function: $message" );
	is( Business::AU::ABN->errstr, $error, "Full Function: $message" );
	is( Business::AU::ABN::errstr(), $error, "Full Function: $message" );

	# Check the class method form
	is( Business::AU::ABN->validate_abn( $value ), '', "Class method: $message" );
	is( $Business::AU::ABN::errstr, $error,  "Class method: $message" );
	is( Business::AU::ABN->errstr, $error, "Class method: $message" );
	is( Business::AU::ABN::errstr(), $error, "Class method: $message" );

	# Check the object contructor form
	is( Business::AU::ABN->new( $value ), '', "Constructor: $message" );
	is( $Business::AU::ABN::errstr, $error, "Constructor: $message" );
	is( Business::AU::ABN->errstr, $error, "Constructor: $message" );
	is( Business::AU::ABN::errstr(), $error, "Constructor: $message" );
}
	
1;
