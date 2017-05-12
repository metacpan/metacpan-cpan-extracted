#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Archlinux::Term' ) || print "Bail out!
";
}

diag( "Testing Archlinux::Term $Archlinux::Term::VERSION, Perl $], $^X" );
