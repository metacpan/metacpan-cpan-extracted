#!perl
use Test::More;

plan 'skip_all' => 'Author does not have Test::Perl::Critic';

if (!eval{require Test::Perl::Critic;1}) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

Test::Perl::Critic::all_critic_ok();
