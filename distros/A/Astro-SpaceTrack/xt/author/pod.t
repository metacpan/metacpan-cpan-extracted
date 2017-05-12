package main;

use strict;
use warnings;

use Test::More 0.96;

BEGIN {

    eval {
	require Test::Pod;
	Test::Pod->VERSION (1.00);
	Test::Pod->import();
	1;
    } or do {
	plan skip_all =>
	    'Test::Pod 1.00 or higher required to test POD validity.';
	exit;
    };

}

all_pod_files_ok();

1;
