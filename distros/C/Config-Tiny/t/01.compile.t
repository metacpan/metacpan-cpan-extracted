#!/usr/bin/perl

# Compile testing for Config::Tiny

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

use_ok('Config::Tiny');
