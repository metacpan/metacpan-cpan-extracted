#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 20;

use Data::Alias;

our ($y, $z);
our $r1;
is \alias($$r1 = $y), \$y;
is $r1, \$y;
is \alias($$r1 = $z), \$z;
is $r1, \$z;

eval { alias local $$r1 = $y };
like $@, qr/^Can't localize through a reference /;

our (@y, @z);
our $r2;
is \alias(@$r2 = @y), \@y;
is $r2, \@y;
is \alias(@$r2 = @z), \@z;
is $r2, \@z;

eval { alias local @$r2 = @y };
like $@, qr/^Can't localize through a reference /;

our (%y, %z);
our $r3;
is \alias(%$r3 = %y), \%y;
is $r3, \%y;
is \alias(%$r3 = %z), \%z;
is $r3, \%z;

eval { alias local %$r3 = %y };
like $@, qr/^Can't localize through a reference /;

alias $r1 = \$y;
is $r1, \$y;
eval { $r1 = undef };
like $@, qr/^Modification of a read-only value attempted /;

alias $r2 = [$y, $z];
is \$r2->[0], \$y;
is \$r2->[1], \$z;
eval {};
eval { $r2 = undef };
like $@, qr/^Modification of a read-only value attempted /;

# vim: ft=perl
