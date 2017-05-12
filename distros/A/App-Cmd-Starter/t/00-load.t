#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Module::Starter::Plugin::App::Cmd' ) || print "Bail out!\n";
}

diag( "Testing Module::Starter::Plugin::App::Cmd $Module::Starter::Plugin::App::Cmd::VERSION, Perl $], $^X" );
