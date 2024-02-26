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

my $filenames = ['lib/Data/Sah/Value/perl/Date/cur_year_local.pm','lib/Data/Sah/Value/perl/Date/cur_year_utc.pm','lib/Data/Sah/Value/perl/Date/datetime/end_of_last_month_local.pm','lib/Data/Sah/Value/perl/Date/datetime/end_of_last_month_utc.pm','lib/Data/Sah/Value/perl/Date/datetime/end_of_yesterday_local.pm','lib/Data/Sah/Value/perl/Date/datetime/end_of_yesterday_utc.pm','lib/Data/Sah/Value/perl/Date/datetime/start_of_this_month_local.pm','lib/Data/Sah/Value/perl/Date/datetime/start_of_this_month_utc.pm','lib/Data/Sah/Value/perl/Date/datetime/start_of_today_local.pm','lib/Data/Sah/Value/perl/Date/datetime/start_of_today_utc.pm','lib/Data/Sah/Value/perl/Date/last_year_local.pm','lib/Data/Sah/Value/perl/Date/last_year_utc.pm','lib/Data/Sah/Value/perl/Date/next_year_local.pm','lib/Data/Sah/Value/perl/Date/next_year_utc.pm','lib/Data/Sah/ValueBundle/Date.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
