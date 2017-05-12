#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
	plan skip_all => "asa is required for this test" unless eval { require asa };
	plan tests => 3;
}

{
	package My::WereDuck;

	use asa  'Duck';

	sub new { bless {}, shift }

	sub quack {
		return "Hi! errr... Quack!";
	}
}

use ok 'Check::ISA' => qw(obj inv);

ok( inv("My::WereDuck", "Duck"), "asa's ->isa is respected as a class method" );
ok( obj(My::WereDuck->new, "Duck"), "and as an instance method" );

