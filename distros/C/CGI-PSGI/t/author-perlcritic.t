
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use Test::More;
eval q{ use Test::Perl::Critic };
plan skip_all => "Test::Perl::Critic is not installed." if $@;
all_critic_ok("lib");
