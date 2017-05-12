#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Archive::Tar::Stream' ) || print "Bail out!\n";
}

diag( "Testing Archive::Tar::Stream $Archive::Tar::Stream::VERSION, Perl $], $^X" );
