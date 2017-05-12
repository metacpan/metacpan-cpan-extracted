#!/usr/bin/perl -w

#for when we are invoked from "make test"
use lib "t";

use strict;
use TEST;

#skip XML::Comma tests if it's not in Configuration.pm
unless(Cache::Static::is_enabled("XML::Comma")) {
	warn "skipping tests - XML::Comma not enabled in Configuration.pm\n";
	print "1..1\nok 1\n";
	exit 0;
}

#if we can't load XML::Comma, skip all tests
eval {
   require XML::Comma;
}; if($@) {
   warn "XML::Comma not found, all related tests skipped";
	print "1..1\nok 1\n";
   exit;
}

use Cache::Static::XML_Comma_Util;

print "1..1\n";

ok ( "name", 1 );

exit 0;
