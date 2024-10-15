#!perl
use 5.010;
use strict;
use warnings;
use Test::More import => [ qw( plan ) ];

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";  ## no critic (ProhibitStringyEval)
if ($@) {
    plan skip_all => "Test::CheckManifest $min_tcm required";
}

ok_manifest();
