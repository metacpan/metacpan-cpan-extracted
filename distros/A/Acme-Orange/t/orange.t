#!/usr/bin/perl -w

use strict;
use Test::More tests => 15;
use Acme::Colour;

BEGIN { use_ok('Acme::Orange'); }

# Hi Leon. I think you may recognise quite a few of your tests here. :-)

my $o = Acme::Orange->new();
is(ref($o), 'Acme::Orange', "should get Acme::Orange object");
is($o->colour, "orange", "should get orange object");

$o = Acme::Orange->new("black");
is(ref($o), 'Acme::Orange', "should get Acme::Orange object");
is("$o", "orange", "should get orange");

$o->add("red");
is($o->colour, "orange", "Orange *is* the only fruit");

my $c = Acme::Colour->new("black");
ok($c, "should get colour");
is("$c", "black", "should get black");
$c->add($o);
is($c->colour, "orange", "Should be able to add Acme::Orange objects to Acme::Colour objects");

$c = Acme::Colour->new("green");
ok($c, "should get colour");
is("$c", "green", "should get green");
$c->add($o);
# I'm not confident that this will work reliably everywhere
is($c->colour, "yellow", "green + orange is yellow");

$c = Acme::Colour->new("green");
ok($c, "should get colour");
is("$c", "green", "should get green");
$o->add($c);
is($o->colour, "orange", "orange + green is orange");
