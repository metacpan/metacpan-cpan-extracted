use Test::More;
use Acme::MetaSyntactic ();
use strict;

my @modules = map { "Acme::MetaSyntactic::$_" } Acme::MetaSyntactic->themes;
    
plan tests => scalar @modules;
use_ok( $_ ) for sort @modules;
