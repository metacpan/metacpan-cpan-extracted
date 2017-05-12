use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Template::Haml' ) || print "Bail out!
";
}

diag( "Testing Dancer::Template::Haml $Dancer::Template::Haml::VERSION, Perl $], $^X" );
