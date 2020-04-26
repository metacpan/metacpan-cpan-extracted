#!perl -T
use 5.006;
use strict;
use warnings;

use Test::Perl::Critic;
use Test2::V0;

unless ( $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

critic_ok('lib/Astro/DSS/JPEG.pm');

done_testing;
