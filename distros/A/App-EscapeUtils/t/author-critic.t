#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.003

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/App/EscapeUtils.pm','script/backslash-escape','script/backslash-unescape','script/html-escape','script/html-unescape','script/js-escape','script/js-unescape','script/perl-dquote-escape','script/perl-squote-escape','script/pod-escape','script/shell-escape','script/uri-escape','script/uri-unescape'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
