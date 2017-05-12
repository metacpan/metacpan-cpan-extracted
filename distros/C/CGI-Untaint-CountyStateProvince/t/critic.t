#!perl -wT

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

unless($ENV{RELEASE_TESTING}) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Perl::Critic";

plan(skip_all => 'Test::Perl::Critic not installed; skipping') if $@;

all_critic_ok();
