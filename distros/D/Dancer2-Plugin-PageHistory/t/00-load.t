#!perl

use Test::More tests => 1;

BEGIN {
    $ENV{PATH} = '/bin:/usr/bin';
    use_ok( 'Dancer2::Plugin::PageHistory' ) || print "Bail out!
";
}

diag( "Testing Dancer2::Plugin::PageHistory $Dancer2::Plugin::PageHistory::VERSION, Perl $], $^X" );
