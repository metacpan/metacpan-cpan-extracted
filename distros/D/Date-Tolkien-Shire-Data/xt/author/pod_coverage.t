package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->VERSION(1.00);
	Test::Pod::Coverage->import();
	1;
    } or do {
	print <<eod;
1..0 # skip Test::Pod::Coverage 1.00 or greater required.
eod
	exit;
    };
}

all_pod_coverage_ok ({
	private	=> [
	    qr{ \A _ (?: \z | (?= [^_] ) ) }smx,
	],
	also_private => [
	    qr{ \A [[:upper:][0-9]_]+ \z }smx,
	],
	coverage_class => 'Pod::Coverage::CountParents'
    });

1;

# ex: set textwidth=72 :
