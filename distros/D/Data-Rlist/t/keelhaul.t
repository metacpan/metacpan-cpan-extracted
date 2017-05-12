#!/usr/bin/perl
#
# keelhaul.t
#
# Before `make install' is performed this script should be runnable with `make
# test'. After `make install' it should work as `perl Data-Rlist.t'
#
# $Writestamp: 2008-07-20 23:21:56 andreas$
# $Compile: perl -M'constant standalone => 1' keelhaul.t$

#########################

use warnings;
use strict;
use constant;
use Test;

BEGIN { plan tests => 2, todo => [ ] };
BEGIN { unshift @INC, '../lib' if $constant::declared{'main::standalone'} }

use Data::Rlist qw/deep_compare keelhaul/;

########################
# Keelhauling, deep-comparion.
#
{
	ok(!deep_compare(undef, undef) &&
	    deep_compare(undef, 1));
	ok(!deep_compare(42, 42) &&
	   !deep_compare(['fee', 'fie', {'foo' => undef}],
					 ['fee', 'fie', {'foo' => undef}]));
}

#########################

### Local Variables:
### buffer-file-coding-system: iso-latin-1
### End:
