#!perl -T

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Spec;
use Test::More;
 
plan( skip_all => 'Author tests not required for installation.' )
	unless $ENV{'RELEASE_TESTING'};

eval { require Test::Perl::Critic; };
plan( skip_all => 'Test::Perl::Critic required.' )
	if $EVAL_ERROR;
 
Test::Perl::Critic->import( -profile => '.perlcriticrc' );
all_critic_ok();
