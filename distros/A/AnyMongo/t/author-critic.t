
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use Test::More;
eval q{ use Test::Perl::Critic(-profile => 'xt/perlcriticrc') };
plan skip_all => "Test::Perl::Critic is not installed." if $@;
all_critic_ok("lib");
