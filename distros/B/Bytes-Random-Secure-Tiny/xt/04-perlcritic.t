#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use English qw( -no_match_vars );

# It's possible users would have their own conflicting Perl::Critic config, so
# it would be a bad idea to make this test run automatically on users systems.

if ( not $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author Test: Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; 1; };

if ($EVAL_ERROR) {
    my $msg = 'Author Test: Test::Perl::Critic required to criticise code.';
    plan( skip_all => $msg );
}

# We want to test the primary module components (blib/) as well as the
# test suite (t/).
my @directories = qw{  blib/  t/  };

Test::Perl::Critic::all_critic_ok(@directories);
