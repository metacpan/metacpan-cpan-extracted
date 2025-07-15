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

my $filenames = ['lib/App/SubtitleUtils.pm','script/hms-secs','script/rename-subtitle-files-like-their-movie-files','script/srtadjust','script/srtcheck','script/srtcombine2text','script/srtcombinetext','script/srtparse','script/srtrenumber','script/srtscale','script/srtshift','script/srtsplit','script/subscale','script/subshift','script/vtt2srt'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
