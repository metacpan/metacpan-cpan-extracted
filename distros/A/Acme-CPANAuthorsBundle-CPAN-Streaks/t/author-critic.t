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

my $filenames = ['lib/Acme/CPANAuthors/CPAN/Streaks/DailyDistributions.pm','lib/Acme/CPANAuthors/CPAN/Streaks/DailyNewDistributions.pm','lib/Acme/CPANAuthors/CPAN/Streaks/DailyReleases.pm','lib/Acme/CPANAuthors/CPAN/Streaks/MonthlyDistributions.pm','lib/Acme/CPANAuthors/CPAN/Streaks/MonthlyNewDistributions.pm','lib/Acme/CPANAuthors/CPAN/Streaks/MonthlyReleases.pm','lib/Acme/CPANAuthors/CPAN/Streaks/WeeklyDistributions.pm','lib/Acme/CPANAuthors/CPAN/Streaks/WeeklyNewDistributions.pm','lib/Acme/CPANAuthors/CPAN/Streaks/WeeklyReleases.pm','lib/Acme/CPANAuthorsBundle/CPAN/Streaks.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
