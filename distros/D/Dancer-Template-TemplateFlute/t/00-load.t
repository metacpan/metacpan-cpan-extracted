#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Template::TemplateFlute' ) || print "Bail out!
";
}

diag( "Testing Dancer::Template::TemplateFlute $Dancer::Template::TemplateFlute::VERSION, Perl $], $^X" );
