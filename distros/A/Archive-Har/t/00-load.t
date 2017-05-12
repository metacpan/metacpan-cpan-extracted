#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Archive::Har' ) || print "Bail out!
";
}

diag( "Testing Archive::Har $Archive::Har::VERSION, Perl $], $^X" );
