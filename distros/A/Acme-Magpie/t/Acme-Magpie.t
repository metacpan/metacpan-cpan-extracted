#!perl
use strict;
use Test::More tests => 5;

# a bit less quirky, hopefully squeeze out that heisenbug

sub f00 { }

require_ok('Acme::Magpie::l33t');
Acme::Magpie::l33t->import;

is_deeply( [ sort keys %Acme::Magpie::Nest ],
    ["main::f00"], "Stole main::f00" );

eval { main->f00() };
ok( $@, "f00 really went" );

Acme::Magpie->unimport;
eval { main->f00() };
ok( !$@, "f00 came back" );

ok( 1, "Everything ran" );

