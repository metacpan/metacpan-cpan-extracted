package main;

use strict;
use warnings;

use File::Spec;

BEGIN {
    eval {
	require Test::More;
	Test::More->VERSION(0.88);
	Test::More->import();
	1;
    } or do {
	print "1..0 # skip Test::More required to criticize code.\n";
	exit;
    };
    eval {
	require Test::Perl::Critic;
	Test::Perl::Critic->import(
	    -profile => File::Spec->catfile(qw{xt author perlcriticrc}));
	1;
    } or do {
	print "1..0 # skip Test::Perl::Critic required to criticize code.\n";
	exit;
    };
}

all_critic_ok();

1;
