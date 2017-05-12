#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Alien::V8;

can_ok("Alien::V8", "incdir");
can_ok("Alien::V8", "libdir");
