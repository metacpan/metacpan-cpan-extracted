#!perl

use Test::More;
plan 'skip_all' => "Author tests not required for installation"
  unless $ENV{'AUTOMATED_TESTING'};

eval { require Test::Perl::Critic };

if ($@) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

Test::Perl::Critic::all_critic_ok();
