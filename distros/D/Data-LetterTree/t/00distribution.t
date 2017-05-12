#!/usr/bin/perl
# $Id: 00distribution.t,v 1.1 2005/12/05 21:30:02 rousse Exp $

use Test::More;

BEGIN {
    eval {
	require Test::Distribution;
    };
    if($@) {
	plan skip_all => 'Test::Distribution not installed';
    } else {
	import Test::Distribution not => 'versions';
    }
}
