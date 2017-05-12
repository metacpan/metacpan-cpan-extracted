#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';

use DataExtract::FixedWidth;
use IO::File;

use Test::More tests => 2;

use File::Spec;
my $file = File::Spec->catfile( 't', 'data', 'NullFirstRow.txt' );
my $fh = IO::File->new( $file );
my @lines = grep /\w/, $fh->getlines;

my $defw = DataExtract::FixedWidth->new({
	heuristic => \@lines
	, skip_header_data => 0
	, null_as_undef    => 1
});

is (
	$defw->unpack_string
	, 'a12a12a5a7A*'
	, 'trailing fields does not exist'
);

my @data;
for ( @lines ) {
	push @data, \@{$defw->parse($_)};
}

my $test_against = [
	[
		'foobarbaz',
		'foobarbaz',
		undef,
		undef,
		undef
	],
	[
		'foobarbaz',
		'foobarbaz',
		undef,
		undef,
		undef
	],
	[
		'foobarbaz',
		'foobarbaz',
		undef,
		undef,
		undef
	],
	[
		undef,
		'WWWWWWWWW',
		'TTTT',
		'TTTT',
		'FFFFFFFFF'
	],
	[
		undef,
		'TTTTTTTTT',
		'TTTT',
		'TTTT',
		'FFFFFFFFF'
	],
	[
		undef,
		'FFFFFFFFF',
		'TTTT',
		'TTTT',
		'FFFFFFFFF'
	]
];

is_deeply ( \@data, $test_against, 'table yield good' );

1;
