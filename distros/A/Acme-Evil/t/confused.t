#!/usr/bin/perl
use lib '.';
use Test::More tests => 6;

ok !eval {require t::t4::ConfusedStrict1 }, 'Confused strict 1 dies';
%evil::wants_strict = ();
ok !eval {require t::t4::ConfusedIntermediate1 }, 'Confused intermediate 1 dies';
ok !eval {require t::t4::ConfusedLax1 }, 'Confused lax 1 dies';
ok !eval {require t::t4::ConfusedStrict2 }, 'Confused strict 2 dies';
%evil::wants_strict = ();
ok !eval {require t::t4::ConfusedIntermediate2 }, 'Confused intermediate 2 dies';
ok !eval {require t::t4::ConfusedLax2 }, 'Confused lax 2 dies';
