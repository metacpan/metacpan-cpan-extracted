#!/usr/bin/perl

use 5.008005;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

require_ok( 'CPANDB' );
