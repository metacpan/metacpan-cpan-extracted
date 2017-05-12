#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Template::HtmlTemplate' ) || print "Bail out!
";
}

diag( "Testing Dancer::Template::HtmlTemplate $Dancer::Template::HtmlTemplate::VERSION, Perl $], $^X" );
