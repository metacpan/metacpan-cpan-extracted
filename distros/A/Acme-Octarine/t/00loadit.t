#!/usr/bin/perl -w

use strict;
use Test::More tests => 7;


use Acme::Octarine;
ok("We loaded");

my $gotit = 0;

my $c = Acme::Colour->new("orange");

isa_ok($c, 'Acme::Colour', "should get Acme::Colour object");
is($c->colour, "orange", "and it shall be orange");
is($gotit, 0, "and nothing special shall have happend");

$Acme::Colour::specials{orange} = sub {
  $gotit++;
  $_[0];
};

$c = Acme::Colour->new("orange");

is($gotit, 1, "this time something special should have happend");
isa_ok($c, 'Acme::Colour', "should get Acme::Colour object");
is($c->colour, "orange", "and it shall be orange");
