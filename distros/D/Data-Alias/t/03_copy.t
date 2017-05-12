#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 14;

use Data::Alias 'copy';

sub refs { [map "".\$_, @_] }

is copy($_), $_  for 1 .. 3;

our $x = 42;
our $y = 43;
our $z = 44;

is copy($x), $x;
is copy { $x }, $x;
isnt \copy($x), \$x;
isnt \copy { $x }, \$x;

is_deeply [copy $x, $y, $z], [$x, $y, $z];
our @r = refs(copy $x, $y, $z);
isnt $r[0], \$x;
isnt $r[1], \$y;
isnt $r[2], \$z;

sub mortal { 42 }
sub nonmortal () { 42 }

$x = "".\mortal;
$y = "".\copy mortal;
is $x, $y;

$x = "".\nonmortal;
$y = "".\copy nonmortal;
isnt $x, $y;

$x = "".\scalar copy();
$y = "".\undef;
isnt $x, $y;

# vim: ft=perl
