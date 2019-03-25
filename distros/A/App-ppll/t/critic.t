#!/usr/bin/env perl

# Test that the module passes perlcritic

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use Test::DescribeMe qw( author );

use Perl::Critic;
use Test::Perl::Critic;

Test::Perl::Critic->import( -profile => '.perlcriticrc' );

all_critic_ok( qw( bin lib t ) );
