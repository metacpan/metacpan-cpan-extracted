#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::MetaCPAN::Gtk2::Notify' ) || print "Bail out!\n";
}

diag( "Testing App::MetaCPAN::Gtk2::Notify $App::MetaCPAN::Gtk2::Notify::VERSION, Perl $], $^X" );
