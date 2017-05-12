#!/usr/bin/env perl -w

use strict;
use lib::abs '../lib';
BEGIN { $ENV{DEBUG_MEM} = 1 }
use Dash::Leak;

{
	leaksz "leak test by scope 1";
	my $mem = 'x'x10000000;
}

{
	leaksz "leak test by scope 2 : begin";
	my $mem1 = 'x'x10000000;
	leaksz "leak test by scope 2 : stage1";
	my $mem1 = 'x'x10000000;
}
