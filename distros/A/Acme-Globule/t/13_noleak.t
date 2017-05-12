#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 1;

package First;
use Acme::Globule qw( Range );

package main;

is_deeply([<1..5>], [ '1..5' ],
          "Use of Acme::Globule in other package doesn't affect us");
