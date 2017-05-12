#!perl -T
use 5.012;
use strict;
use warnings;
use Test::More;

if ( $ENV{TRAVIS_PERL_VERSION} ) {
    plan( skip_all => "Detected Travis environment - skipping test" );
}

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();
