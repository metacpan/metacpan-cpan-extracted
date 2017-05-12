#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Blog::Blosxom' ) || print "Bail out!
";
}

diag( "Testing Blog::Blosxom $Blog::Blosxom::VERSION, Perl $], $^X" );
