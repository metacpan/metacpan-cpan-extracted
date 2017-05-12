#!perl -T

use strict;
use warnings;
use Test::More;
use Carp;

eval {
    require Test::CheckManifest;
    croak if ( $Test::CheckManifest::VERSION < 0.9 );
    Test::CheckManifest->import();
};
plan skip_all => "Test::CheckManifest 0.9 required" if $@;
ok_manifest();
