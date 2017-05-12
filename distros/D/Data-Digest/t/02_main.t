#!/usr/bin/perl

# Compile-testing for Data::Digest

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 24;
use File::Spec::Functions ':ALL';
use Data::Digest;

# Find the test file
my $test_file = catfile('t', 'pandas.jpg');
ok( -f $test_file, 'Test file exists'      );
ok( -r $test_file, 'Test file is readable' );

ok( open( TESTFILE, $test_file ), "open($test_file) ok" );
ok( binmode(TESTFILE), "binmode($test_file) ok" );
my $test_data = do { local $/; <TESTFILE>; };
ok( close(TESTFILE), "close($test_file) ok" );
is( length($test_data), 3084, 'Read in correct number of bytes from test file' );





#####################################################################
# Main Tests

# Creating objects
my $digest1 = Data::Digest->new('MD5.81686241319c589f3ebdd71cf8a39577');
my $digest2 = Data::Digest->new('MD5', '81686241319c589f3ebdd71cf8a39577');
isa_ok( $digest1, 'Data::Digest' );
isa_ok( $digest2, 'Data::Digest' );
is_deeply( $digest1, $digest2, 'One and two-argument forms of new create the same thing' );
is( $digest1->as_string, 'MD5.81686241319c589f3ebdd71cf8a39577', '->as_string returns as expected' );
is( $digest2->as_string, 'MD5.81686241319c589f3ebdd71cf8a39577', '->as_string returns as expected' );

# Matching a file (also tests handle)
ok( $digest1->matches( $test_file ), 'Matched test file ok' );
ok( $digest1->matches( \$test_data ), 'Matched test data ok' );

# Negative matching
my $nomatch_data = "foo";
ok( defined $digest1->matches( 'Changes' ),      'Non-match returns defined' );
ok( defined $digest1->matches( \$nomatch_data ), 'Non-match returns defined' );
ok( ! $digest1->matches( 'Changes' ),      'Did not match file, as expected' );
ok( ! $digest1->matches( \$nomatch_data ), 'Did not match data, as expected' );

# Error testing
eval { Data::Digest->new() };
ok( $@ =~ /Missing or invalid params/,
	'Got expected error for ->new()' );
eval { Data::Digest->new('MD5bad') };
ok( $@ =~ /Unrecognised or unsupported Data::Digest string/,
	'Got expected error for ->new(bad)' );
eval { Data::Digest->new('Whirlpool', 'FOO') };
ok( $@ =~ /Invalid or unsupported digest type/,
	'Got expected error for ->new(Whirlpool)' );





#####################################################################
# Digest testing

# Confirm we can create the required digest types
use Digest;

foreach ( qw{MD5 SHA-1 SHA-256 SHA-512} ) {
	my $d = Digest->new($_);
	isa_ok( $d, 'Digest::base' );
}
