#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CPANPLUS::Dist::Slackware' ) || print "Bail out!\n";
}

diag( "Testing CPANPLUS::Dist::Slackware $CPANPLUS::Dist::Slackware::VERSION, Perl $], $^X" );
