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

my $filenames = ['lib/BorderStyle/ASCII/None.pm','lib/BorderStyle/ASCII/SingleLine.pm','lib/BorderStyle/ASCII/SingleLineHorizontalOnly.pm','lib/BorderStyle/ASCII/SingleLineInnerOnly.pm','lib/BorderStyle/ASCII/SingleLineOuterOnly.pm','lib/BorderStyle/ASCII/SingleLineVerticalOnly.pm','lib/BorderStyle/ASCII/Space.pm','lib/BorderStyle/ASCII/SpaceInnerOnly.pm','lib/BorderStyle/BoxChar/None.pm','lib/BorderStyle/BoxChar/SingleLine.pm','lib/BorderStyle/BoxChar/SingleLineHorizontalOnly.pm','lib/BorderStyle/BoxChar/SingleLineInnerOnly.pm','lib/BorderStyle/BoxChar/SingleLineOuterOnly.pm','lib/BorderStyle/BoxChar/SingleLineVerticalOnly.pm','lib/BorderStyle/BoxChar/Space.pm','lib/BorderStyle/BoxChar/SpaceInnerOnly.pm','lib/BorderStyle/UTF8/Brick.pm','lib/BorderStyle/UTF8/BrickOuterOnly.pm','lib/BorderStyle/UTF8/DoubleLine.pm','lib/BorderStyle/UTF8/None.pm','lib/BorderStyle/UTF8/SingleLine.pm','lib/BorderStyle/UTF8/SingleLineBold.pm','lib/BorderStyle/UTF8/SingleLineCurved.pm','lib/BorderStyle/UTF8/SingleLineHorizontalOnly.pm','lib/BorderStyle/UTF8/SingleLineInnerOnly.pm','lib/BorderStyle/UTF8/SingleLineOuterOnly.pm','lib/BorderStyle/UTF8/SingleLineVerticalOnly.pm','lib/BorderStyle/UTF8/Space.pm','lib/BorderStyle/UTF8/SpaceInnerOnly.pm','lib/BorderStyles/Standard.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
