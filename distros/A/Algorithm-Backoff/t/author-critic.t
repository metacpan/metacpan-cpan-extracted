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

my $filenames = ['lib/Algorithm/Backoff.pm','lib/Algorithm/Backoff/Constant.pm','lib/Algorithm/Backoff/Exponential.pm','lib/Algorithm/Backoff/Fibonacci.pm','lib/Algorithm/Backoff/LILD.pm','lib/Algorithm/Backoff/LIMD.pm','lib/Algorithm/Backoff/MILD.pm','lib/Algorithm/Backoff/MIMD.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
