#!/usr/bin/perl -T

use strict;
use warnings;

use File::Spec;

BEGIN {
	use Test::More;
	if (not $ENV {'TEST_AUTHOR'}) {
		plan ('skip_all' => 'Set $ENV{TEST_AUTHOR} to a true value to run the tests');
	}
}

BEGIN {
	eval 'require Test::Perl::Critic';
	plan ('skip_all' => 'Test::Perl::Critic required for criticizing code') if $@;
}

my $rcfile = File::Spec -> catfile ('t', 'perlcriticrc');
Test::Perl::Critic -> import ('-profile' => $rcfile);

all_critic_ok ();
