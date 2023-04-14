#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Prove::Plugin::KohaBootstrap' ) || print "Bail out!\n";
}

diag( "Testing App::Prove::Plugin::KohaBootstrap $App::Prove::Plugin::KohaBootstrap::VERSION, Perl $], $^X" );
