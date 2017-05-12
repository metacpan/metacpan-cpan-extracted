#!/usr/bin/perl -w

use strict;
use Test::Simple tests => 4;
BEGIN {
    eval { use Acme::PETEK::Testkit; };
    ok(!$@,'module loads OK');
}

my $c = Acme::PETEK::Testkit->new;
ok($c,'object returned');

$c->incr;
ok($c->value == 1,'first increment goes to 1');
ok($c->sign eq 'positive','counter sign is positive');
