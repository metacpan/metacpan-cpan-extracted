#!/bin/env perl

# Run Perl::Critic on the perl code (not the entire distro, yet).

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if (not $ENV{TEST_AUTHOR}) {
    my $msg = 'Author test. Set TEST_AUTHOR to run.';
    plan(skip_all => $msg);
}

eval { require Test::Perl::Critic; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan(skip_all => $msg);
}

my $rcfile = File::Spec->catfile('t', 'perlcriticrc');
Test::Perl::Critic->import(-profile => $rcfile);

#all_critic_ok();

all_critic_ok('lib');
