#!/usr/bin/env perl -w

use Test::More;

#$ENV{TEST_AUTHOR} or plan skip_all => '$ENV{TEST_AUTHOR} not set';

eval { require Test::Perl::Critic; 1; };
plan( skip_all => 'Test::Perl::Critic not installed; skipping' ) if $@;

Test::Perl::Critic->import( -profile => 'perlcritic.conf' );
Test::Perl::Critic::all_critic_ok();
