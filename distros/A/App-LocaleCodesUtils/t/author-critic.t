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

my $filenames = ['lib/App/LocaleCodesUtils.pm','lib/App/LocaleCodesUtils/ListCountries.pm','lib/App/LocaleCodesUtils/ListCurrencies.pm','lib/App/LocaleCodesUtils/ListLanguages.pm','lib/App/LocaleCodesUtils/ListScripts.pm','script/country-code2code','script/language-code2code','script/list-countries','script/list-currencies','script/list-languages','script/list-scripts'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
