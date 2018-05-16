#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use File::Spec;

use_ok( 'Brick' );
use_ok( 'Brick::Bucket' );
use_ok( 'Brick::Files' );

ok( defined &Brick::Bucket::_get_file_extensions_by_mime_type,
	"_get_file_extensions_by_mime_type sub is there");

my $bucket = 'Brick::Bucket';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# These things should work
my %types = (
	'application/vnd.ms-excel' => [ qw(xls xlt) ],
	'application/x-msword'     => [ qw(doc dot) ],
	'text/plain'               => [ qw(txt) ],
	);

foreach my $type ( sort keys %types )
	{
	my @extensions = $bucket->_get_file_extensions_by_mime_type( $type );
	ok( scalar @extensions, "$type got some extensions back! (good)" )
		or diag "$type: @extensions";

	my %extensions = map { $_, 1 } @extensions;
	my %types      = map { $_, 1 } @{ $types{$type} };

	foreach my $t ( sort keys %types )
		{
		ok( exists $extensions{$t}, "Found $t for $type" );
		}
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# These things should not work (get an empty list)
{
no warnings 'uninitialized';

my @types = (
	'x-system/x-error', undef, -1, 0
	);

foreach my $type ( sort @types )
	{
	no warnings;
	my @extensions = $bucket->_get_file_extensions_by_mime_type( $type );
	is( scalar @extensions, 0, "$type has no extensions! (good)" );
#	diag "$type: @extensions";
	}

}
