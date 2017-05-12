#!/usr/bin/perl

use strict;
use Test::More tests => 3;

BEGIN { use_ok "Acme::VerySign" }

sub willow {}

is(wilow()."", "64.94.110.11", "yep, that works");
ok(defined(wilow()->[0]),"returned a listref");