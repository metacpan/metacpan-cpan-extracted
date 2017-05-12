#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Paginate' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::Paginate $Dancer::Plugin::Paginate::VERSION, Perl $], $^X" );
