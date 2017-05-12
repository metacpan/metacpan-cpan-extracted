#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Daemon::Control::Plugin::HotStandby' ) || print "Bail out!\n";
}

diag( "Testing Daemon::Control::Plugin::HotStandby $Daemon::Control::Plugin::HotStandby::VERSION, Perl $], $^X" );
