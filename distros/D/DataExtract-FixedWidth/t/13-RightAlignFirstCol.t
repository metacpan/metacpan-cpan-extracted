#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';

use DataExtract::FixedWidth;
use IO::File;

use Test::More tests => 1;

use File::Spec;
my $file = File::Spec->catfile( 't', 'data', 'RightAlign1Col.txt' );
my $fh = IO::File->new( $file );
my @lines = grep /\w/, $fh->getlines;

my $defw = DataExtract::FixedWidth->new({
	heuristic => \@lines
});

# 'a8a5a7a7A*' In pre v0.9 releases.
#say $defw->unpack_string;

is (
	$defw->unpack_string
	, 'a11a5a7a7A*'
	, 'Spaces on left pass - right align ready'
);
