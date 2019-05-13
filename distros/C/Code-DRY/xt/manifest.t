#!perl -T

use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;
ok_manifest({'exclude' => ['/_build'], 'filter' => [qr{salcpis.o|DRY\.(?:c|o|xs|bs)}xms]});
