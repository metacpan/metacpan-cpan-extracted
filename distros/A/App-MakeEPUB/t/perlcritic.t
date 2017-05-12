#!perl

use Test::More;
eval "use Test::Perl::Critic";
plan skip_all => "Test::Perl::Critic required to test PBP compliance" if $@;

if (not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

Test::Perl::Critic::all_critic_ok();
