#!perl -w

use strict;
use Test qw(plan ok);
plan tests => 2;

use Data::Dump::Perl6 qw(dump_perl6);

ok(dump_perl6(*STDIN), '$*IN');
ok(dump_perl6(\*STDIN), '$*IN');
