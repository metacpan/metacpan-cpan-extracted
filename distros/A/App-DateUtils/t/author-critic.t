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

my $filenames = ['lib/App/DateUtils.pm','script/dateconv','script/datediff','script/durconv','script/parse-date','script/parse-date-using-df-alami-en','script/parse-date-using-df-alami-id','script/parse-date-using-df-flexible','script/parse-date-using-df-natural','script/parse-duration','script/parse-duration-using-df-alami-en','script/parse-duration-using-df-alami-id','script/parse-duration-using-df-natural','script/parse-duration-using-td-parse','script/strftime','script/strftimeq'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
