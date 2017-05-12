#!/usr/bin/perl -w

#for when we are invoked from "make test"
use lib "t";

use strict;
use TEST;

use Cache::Static;

#skip HTML::Mason tests if it's not in Configuration.pm
unless(Cache::Static::is_enabled("HTML::Mason")) {
	warn "skipping tests - HTML::Mason not enabled in Configuration.pm\n";
	print "1..1\nok 1\n";
	exit 0;
}

#if we can't load HTML::Mason & HTML::Mason::Tests, skip all tests
eval {
   require HTML::Mason;
	require HTML::Mason::Tests;
}; if($@) {
   warn "HTML::Mason not found, all related tests skipped";
	print "1..1\nok 1\n";
   exit;
}

use Cache::Static::HTML_Mason_Util;

print "1..1\n";

ok ( "name", 1 );

exit 0;
