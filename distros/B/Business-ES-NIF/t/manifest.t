#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => 'Author test: set RELEASE_TESTING=1 to run this test' );
}

my $min_version = 0.9;


eval {
    require Test::CheckManifest;
    Test::CheckManifest->VERSION($min_version);
    *main::ok_manifest = \&Test::CheckManifest::ok_manifest;
    1;
} or plan skip_all => "Test::CheckManifest $min_version required: $@";

# Ya podemos usar ok_manifest
ok_manifest({ verbose => 1 });
