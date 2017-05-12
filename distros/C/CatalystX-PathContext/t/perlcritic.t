#!perl

use strict;
use warnings;

use Test::More;

if ( ! $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval 'use Test::Perl::Critic -severity => 3';
plan skip_all => 'Test::Perl::Critic required for testing PBP compliance' if $@;

Test::Perl::Critic::all_critic_ok();
