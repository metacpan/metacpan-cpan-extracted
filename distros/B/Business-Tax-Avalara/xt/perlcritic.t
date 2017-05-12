#!perl -T

use strict;
use warnings;

use File::Spec;
use Test::More;

 
# Load Test::Perl::Critic.
eval
{
	require Test::Perl::Critic;
};
plan( skip_all => 'Test::Perl::Critic required.' )
	if $@;

# Run PerlCritic.
Test::Perl::Critic->import( -profile => '.perlcriticrc' );
all_critic_ok();
