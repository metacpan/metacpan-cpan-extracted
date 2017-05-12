#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';

##
## In version .06 this test failed
## I got the longer a19a9a14a13a5A* instead of a19a9a14a13A*
## This was because the length for the heuristic was set statically to the
## first row rather than the longest row
##

use DataExtract::FixedWidth;
use IO::File;

use Test::More tests => 1;

use File::Spec;
my $file = File::Spec->catfile( 't', 'data', 'larochenew.TXT' );
my $fh = IO::File->new( $file );
my @lines = grep /\w/, $fh->getlines;

my $defw = DataExtract::FixedWidth->new({
	heuristic => \@lines
	, cols    => [ qw/vin stock color price miles/ ]
	, header_row => undef
});

is ( $defw->unpack_string, 'a19a9a14a13A*', 'Heuristic not affected by being short' );

1;
