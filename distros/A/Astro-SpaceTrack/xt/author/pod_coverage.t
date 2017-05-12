package main;

use strict;
use warnings;

use Test::More 0.96;

BEGIN {

    eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->VERSION(1.00);
	Test::Pod::Coverage->import();
	1;
    } or do {
	plan skip_all => 'Test::Pod::Coverage 1.00 or greater required.';
	exit;
    };

}

all_pod_coverage_ok ({
	also_private => [ qr{^[[:upper:]\d_]+$}, qr{^parse_(?:string|file)$} ],
	coverage_class => 'Pod::Coverage::CountParents'
    });

1;
