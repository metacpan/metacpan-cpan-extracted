#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
}

use t::lib::Test;
use Test::More tests => 1;

setup_schema_ok('music');

