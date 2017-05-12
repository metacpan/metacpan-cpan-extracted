#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Rad::Plugin::Daemonize' );
}

diag( "Testing App::Rad::Plugin::Daemonize $App::Rad::Plugin::Daemonize::VERSION, Perl $], $^X" );
