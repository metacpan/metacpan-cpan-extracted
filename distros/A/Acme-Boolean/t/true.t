#!/usr/bin/env perl

use Acme::Boolean;
use Test::More;

plan tests => 12;

ok true, "true";
ok correct, "correct";
ok accurate, "accurate";
ok right, "right";
ok verifiable, "verifiable";
ok truthful,"truthful";
ok trusty, "trusty";
ok yes, "yes";
ok EXACT, "EXACT";
ok PURE, "PURE";
ok CORRECT, "CORRECT";

my $v = (NO, really not fishy);
ok $v, "NO, really not fishy";
