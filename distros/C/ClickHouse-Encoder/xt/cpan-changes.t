#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run author tests'
    unless $ENV{RELEASE_TESTING};

eval { require Test::CPAN::Changes; Test::CPAN::Changes->import };
plan skip_all => 'Test::CPAN::Changes required' if $@;

changes_ok();
