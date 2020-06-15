#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/ColorTransform/Darken.pm','lib/ColorTransform/DuotoneCyan.pm','lib/ColorTransform/DuotoneGreen.pm','lib/ColorTransform/DuotoneRandom.pm','lib/ColorTransform/Grayscale.pm','lib/ColorTransform/Lighten.pm','lib/ColorTransform/Monotone.pm','lib/ColorTransform/Noop.pm','lib/ColorTransform/Reverse.pm','lib/ColorTransform/Sepia.pm','lib/ColorTransform/Tint.pm','lib/ColorTransform/Weight.pm','lib/ColorTransforms/Standard.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
