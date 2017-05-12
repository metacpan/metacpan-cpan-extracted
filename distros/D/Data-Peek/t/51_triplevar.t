#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 33;
use Test::NoWarnings;

use Data::Peek qw( DDual DPeek triplevar );

foreach         my $iv (undef, 3     ) {
    foreach     my $nv (undef, 3.1415) {
	foreach my $pv (undef, "\x{03c0}") {
	    my $tv = triplevar ($pv, $iv, $nv);
	    ok (my @tv = DDual ($tv),	"Get tv");
	    is ($tv[0], $pv,		"Check pv");
	    is ($tv[1], $iv,		"Check iv");
	    is ($tv[2], $nv,		"Check nv");
	    }
	}
    }

1;
