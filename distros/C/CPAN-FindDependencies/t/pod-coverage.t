# $Id: pod-coverage.t,v 1.1 2007/08/14 16:42:21 drhyde Exp $
use strict;

$^W=1;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

# Some anonymous functions are showing up as 'BEGIN'
all_pod_coverage_ok( { trustme => [ qr/^BEGIN$/ ] } );
