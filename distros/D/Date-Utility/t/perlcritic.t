#!perl

use strict;
use warnings;
use Test::More;

eval "use Test::Perl::Critic";
plan skip_all => "Test::Perl::Critic required for testing PBP compliance" if $@;
plan skip_all => "These tests are for authors only!" unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};

Test::Perl::Critic->import(-profile => 't/rc/.perlcriticrc');
Test::Perl::Critic::all_critic_ok();
