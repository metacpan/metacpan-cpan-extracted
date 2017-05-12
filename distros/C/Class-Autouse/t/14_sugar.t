#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use Class::Autouse;

my $s;
eval {
	Class::Autouse->sugar(\&magic);

	sub magic {
			my $caller = caller(1);
			my ($class,$method,@params) = @_;
			shift @params; 
			my @words = ($method,$class,@params);
			my $sentence = join(" ",@words);
			return sub { $sentence };
	}

	$s = trolls have big ugly hairy feet;
};

is($s, "trolls have big ugly hairy feet", "magic method works");
ok(!feet->can("hairy"), 'no unexpected methods in the namespace');
ok(!hairy->can("ugly"), 'no unexpected methods in the namespace');
ok(!ugly->can("big"), 'no unexpected methods in the namespace');
