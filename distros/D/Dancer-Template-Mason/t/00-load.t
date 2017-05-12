use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Template::Mason' ) || print "Bail out!
";
}

diag( "Testing Dancer::Template::Mason $Dancer::Template::Mason::VERSION, Perl $], $^X" );
