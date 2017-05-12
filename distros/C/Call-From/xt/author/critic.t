#!perl

use strict;
use warnings;

use Test::More;
use Test::Perl::Critic ( -profile => 'perlcritic.rc' );
all_critic_ok();
