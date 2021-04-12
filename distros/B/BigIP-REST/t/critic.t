#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

plan(skip_all => 'Author test, set $ENV{AUTHOR_TESTING} to a true value to run')
    if !$ENV{AUTHOR_TESTING};

eval { require Test::Perl::Critic; };
plan(skip_all => 'Test::Perl::Critic required') if $EVAL_ERROR;

Test::Perl::Critic->import();
all_critic_ok();
