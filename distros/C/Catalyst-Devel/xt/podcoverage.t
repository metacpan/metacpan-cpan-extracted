use strict;
use warnings;
use Test::More;
use Test::Pod::Coverage 1.04;
use Pod::Coverage 0.20;

all_pod_coverage_ok( { trustme => [ qr/^(?:BUILD|DEMOLISH)$/ ] } );

