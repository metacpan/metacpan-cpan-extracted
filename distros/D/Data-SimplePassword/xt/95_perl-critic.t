# 

use strict;
use Test::More;

if ($ENV{PERL_TEST_CRITIC}) {
  if (eval { require Test::Perl::Critic; import Test::Perl::Critic -profile => "t/perlcriticrc" }) {
    Test::Perl::Critic::all_critic_ok("lib");
  } else {
    plan skip_all => "couldn't load Test::Perl::Critic";
  }
} else {
  plan skip_all => "define PERL_TEST_CRITIC to run these tests";
}

