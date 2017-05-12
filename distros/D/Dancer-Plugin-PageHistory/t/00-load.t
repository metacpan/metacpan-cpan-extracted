#!perl

use Test::More tests => 1;

BEGIN {
    $ENV{PATH} = '/bin:/usr/bin';
    use_ok( 'Dancer::Plugin::PageHistory' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::PageHistory $Dancer::Plugin::PageHistory::VERSION, Perl $], $^X" );
