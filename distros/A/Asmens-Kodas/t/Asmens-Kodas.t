#!/usr/bin/perl -w
use strict;

use Test::More tests => 11;

use Asmens::Kodas qw/tikras/;

is(tikras("38208090214"), 1);
is(tikras("382O8090214"), 0);
is(tikras("38208090215"), 0);
is(tikras("98208090214"), 0);
is(tikras("44107268276"), 1);
is(tikras("44107268277"), 0);
is(tikras("3424234234"), 0);
is(tikras("143423423444"), 0);
is(tikras("55413387665"), 0);
is(tikras("10000000001"), 1);
is(tikras("52310874520"), 0);
