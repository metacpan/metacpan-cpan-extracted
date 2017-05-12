#!/usr/bin/perl
use 5.008009;
use strict;
use warnings;

use Test::More;

BEGIN { plan skip_all => '$ENV{RELEASE_TESTING} is false' unless $ENV{RELEASE_TESTING} }
use Test::Perl::Critic -profile => 't/perlcriticrc';

all_critic_ok
