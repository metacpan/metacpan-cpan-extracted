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

my $filenames = ['lib/App/IndonesianFinanceUtils.pm','script/convert-currency-using-bca','script/convert-currency-using-gmc','script/get-jisdor-rates','script/get-ksei-sec-ownership-url','script/get-usd-idr-rate-from-bca','script/get-usd-idr-rate-from-gmc','script/list-currency-exchange-rates-from-bca','script/list-currency-exchange-rates-from-gmc'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
