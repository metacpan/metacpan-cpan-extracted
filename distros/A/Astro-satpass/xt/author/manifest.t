package main;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing()

BEGIN {
    eval {
	require ExtUtils::Manifest;
	ExtUtils::Manifest->import( qw{ manicheck filecheck } );
	1;
    } or do {
	plan( skip_all => "ExtUtils::Manifest required" );
	exit;
    };
}

plan( tests => 2 );

is( join( ' ', manicheck() ), '', 'Missing files per manifest' );
is( join( ' ', filecheck() ), '', 'Files not in MANIFEST or MANIFEST.SKIP' );

1;
