#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/ColorTheme/Test/Dynamic.pm','lib/ColorTheme/Test/Static.pm','lib/ColorThemeBase/Base.pm','lib/ColorThemeBase/Constructor.pm','lib/ColorThemeBase/Static.pm','lib/ColorThemeBase/Static/FromObjectColors.pm','lib/ColorThemeBase/Static/FromStructColors.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
