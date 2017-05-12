#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


my $rules = require Data::Compare::Plugins::JSON;

is ref($rules), 'ARRAY';
foreach (@$rules) {
	is ref($_), 'ARRAY' or next;

	my ($handler, $type1, undef, @extra) = reverse(@$_);

	ok defined($type1);
	ok !ref($type1);
	is ref($handler), 'CODE';
	ok !@extra;
}


done_testing;
