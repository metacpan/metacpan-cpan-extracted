#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run author tests'
    unless $ENV{RELEASE_TESTING};

eval { require Test::Perl::Critic; Test::Perl::Critic->import(-severity => 4) };
plan skip_all => 'Test::Perl::Critic not installed' if $@;

# Lint the .pm only - the XS file isn't Perl source.
all_critic_ok('lib');
