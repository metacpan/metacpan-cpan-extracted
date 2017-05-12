#!/usr/bin/perl

use strict;

use Test::More tests => 1;
use Acme::VerySign;

sub hello { "Hello World" }

helo()->buy();
is(helo(), "Hello World","bought okay");
