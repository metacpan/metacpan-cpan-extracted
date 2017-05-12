#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::DirectoryView' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::DirectoryView $Dancer::Plugin::DirectoryView::VERSION, Perl $], $^X" );
