#!perl

use strict;
use warnings;

use Test::Perl::Critic (-verbose => 8, -profile => ".perlcriticrc");
all_critic_ok();
