#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 34;

use Data::Alias;

our ($x, $y, $z);
our $T = 42;

is \alias($x = $y), \$y;
is \$x, \$y;
is \alias($x = $z), \$z;
is \$x, \$z;
isnt \$y, \$z;

is \alias($x ||= $T), \$T;
is \$x, \$T;
isnt \alias($x ||= $y), \$y;
is \$x, \$T;
is \alias($x &&= $z), \$z;
is \$x, \$z;
isnt \alias($x &&= $T), \$T;
is \$x, \$z;

alias { is \(local $x = $y), \$y; is \$x, \$y };
is \$x, \$z;

my $gx = *x;

is alias(*$gx = \$y), \$y;
is \$x, \$y;
is \alias($$gx = $z), \$z;
is \$x, \$z;

is \alias($$gx ||= $T), \$T;
is \$x, \$T;
isnt \alias($$gx ||= $y), \$y;
is \$x, \$T;
is \alias($$gx &&= $z), \$z;
is \$x, \$z;
isnt \alias($$gx &&= $T), \$T;
is \$x, \$z;

alias { is +(local *$gx = \$y), \$y; is \$x, \$y };
is \$x, \$z;
alias { is \(local $$gx = $y), \$y; is \$x, \$y };
is \$x, \$z;

# vim: ft=perl
