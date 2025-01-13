#!perl

use Test::More 1;

use_ok( 'App::grepurl' ) or BAIL_OUT( "Module does not compile" );

my $file = "blib/script/grepurl";

print "bail out! Script file is missing!" unless -e $file;
BAIL_OUT( "Script file is missing!" ) unless -e $file;

my $output = `$^X -c $file 2>&1`;

BAIL_OUT( "Script file has a problem!" ) unless
	like( $output, qr/syntax OK/, 'script compiles' );

done_testing();
