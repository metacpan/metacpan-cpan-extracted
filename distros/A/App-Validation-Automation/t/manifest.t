#!perl -T

use strict;
use warnings;
use lib qw( 
    /home/vj504j/App-Validation-Automation-0.01/lib /home/vj504j/perllib
);
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;
ok_manifest();
