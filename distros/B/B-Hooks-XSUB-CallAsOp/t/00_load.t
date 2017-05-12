#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use ok 'B::Hooks::XSUB::CallAsOp';

B::Hooks::XSUB::CallAsOp::__test("magic", "magic", "trampoline", \&is);
B::Hooks::XSUB::CallAsOp::__test("foo", "magic", "trampoline", \&isnt);

pass("returned");
