#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
BEGIN {
    use_ok('Acme::PETEK::Testkit');
}

my $c = Acme::PETEK::Testkit->new;
isa_ok($c, 'Acme::PETEK::Testkit');

$c->incr;
cmp_ok($c->value,'==',1,'first increment goes to 1');
is($c->sign,'positive','counter sign is positive');
