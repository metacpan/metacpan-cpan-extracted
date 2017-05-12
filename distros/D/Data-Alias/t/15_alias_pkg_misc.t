#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 27;

use Data::Alias;

our $x;
our $y = "x";
our $z = *x;

# rv2sv in more detail:

is \alias(${*x} = $y), \$y;  # real gv
is \$x, \$y;
is \alias($$z = $z), \$z;    # fake gv
is \$x, \$z;
eval { alias $$y = $y };     # symref (strict)
like $@, qr/^Can't use string .* as a SCALAR ref /;
is \$x, \$z;
is \alias { no strict 'refs'; $$y = $y }, \$y;  # symref (non-strict)
is \$x, \$y;

# rv2gv in more detail:

is \alias { local *{*x} = *z; $x }, \$z;
is \$x, \$y;
is \alias { local *{\*x} = *z; $x }, \$z;
is \$x, \$y;
is \alias { local *{\$z} = *z; $x }, \$z;
is \$x, \$y;
is \alias { local *$z = *z; $x }, \$z;
is \$x, \$y;
is \alias { eval { local *$y = *z }; $x }, \$y;
like $@, qr/^Can't use string .* as a symbol ref /;
is \alias { no strict 'refs'; local *$y = *z; $x }, \$z;
is \$x, \$y;

eval { my $q; local *$q = *z };
like $@, qr/^Can't use an undefined value as a symbol reference /;

format foo =
.

is alias { local *x = \&foo; \&x }, \&foo;
isnt \&x, \&foo;
is alias { local *x = *foo{FORMAT}; *x{FORMAT} }, *foo{FORMAT};
isnt *x{FORMAT}, *foo{FORMAT};
is alias { local *x = *STDIN{IO}; *x{IO} }, *STDIN{IO};
isnt *x{IO}, *STDIN{IO};

# vim: ft=perl
