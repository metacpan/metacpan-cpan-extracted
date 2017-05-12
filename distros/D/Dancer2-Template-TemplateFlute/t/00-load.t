#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer2::Template::TemplateFlute' ) || print "Bail out!
";
}

diag( "Testing Dancer2::Template::TemplateFlute $Dancer2::Template::TemplateFlute::VERSION, Perl $], $^X" );
