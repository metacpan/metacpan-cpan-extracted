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

my $filenames = ['lib/Acme/CPANAuthors/CPAN/Streaks/DailyDistributions/AllTime.pm','lib/Acme/CPANAuthors/CPAN/Streaks/DailyDistributions/Current.pm','lib/Acme/CPANAuthors/CPAN/Streaks/DailyNewDistributions/AllTime.pm','lib/Acme/CPANAuthors/CPAN/Streaks/DailyNewDistributions/Current.pm','lib/Acme/CPANAuthors/CPAN/Streaks/DailyReleases/AllTime.pm','lib/Acme/CPANAuthors/CPAN/Streaks/DailyReleases/Current.pm','lib/Acme/CPANAuthors/CPAN/Streaks/MonthlyDistributions/AllTime.pm','lib/Acme/CPANAuthors/CPAN/Streaks/MonthlyDistributions/Current.pm','lib/Acme/CPANAuthors/CPAN/Streaks/MonthlyNewDistributions/AllTime.pm','lib/Acme/CPANAuthors/CPAN/Streaks/MonthlyNewDistributions/Current.pm','lib/Acme/CPANAuthors/CPAN/Streaks/MonthlyReleases/AllTime.pm','lib/Acme/CPANAuthors/CPAN/Streaks/MonthlyReleases/Current.pm','lib/Acme/CPANAuthors/CPAN/Streaks/WeeklyDistributions/AllTime.pm','lib/Acme/CPANAuthors/CPAN/Streaks/WeeklyDistributions/Current.pm','lib/Acme/CPANAuthors/CPAN/Streaks/WeeklyNewDistributions/AllTime.pm','lib/Acme/CPANAuthors/CPAN/Streaks/WeeklyNewDistributions/Current.pm','lib/Acme/CPANAuthors/CPAN/Streaks/WeeklyReleases/AllTime.pm','lib/Acme/CPANAuthors/CPAN/Streaks/WeeklyReleases/Current.pm','lib/Acme/CPANAuthorsBundle/CPAN/Streaks.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
