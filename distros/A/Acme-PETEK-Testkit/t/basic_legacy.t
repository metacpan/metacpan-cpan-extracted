#!/usr/bin/perl -w

use strict;
use Test::Legacy;

BEGIN { plan tests => 4; 
        eval {use Acme::PETEK::Testkit; }; ok !$@; 
}

my $c = Acme::PETEK::Testkit->new;
ok $c; 

$c->incr;
ok $c->value, 1, 'first increment goes to 1';
ok $c->sign, 'positive', 'counter sign is positive';
