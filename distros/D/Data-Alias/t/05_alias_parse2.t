#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 17;
use File::Spec;

use Data::Alias qw/alias copy/;

our $x;
our $y;

alias { BEGIN { $x = $y } };

BEGIN { is \$x, \$y; alias $y = copy 42 }

alias { BEGIN { do File::Spec->catfile(qw(t lib assign.pm)) or die $! } };
isnt \$x, \$y;
is $x, 42;

our $z = 1;
alias($x = $y) = $z;
is \$x, \$y;
isnt \$x, \$z;
is $x, $z;

alias { sub foo { $x = $y } };
is \foo, \$y;
is \$x, \$y;

alias(sub { $x = $z })->();
is \$x, \$z;

$x++;
alias { {;} $x } = $y;
is \$x, \$z;
is $x, $y;

eval "{;}\n\nalias { Data::Alias::deref = 42 };\n\n{;}\n";
like $@, qr/^Unsupported alias target .* line 3\b/;

eval "{;}\n\n\$x = alias \$y;\n\n{;}\n";
like $@, qr/^Useless use of alias .* line 3\b/;

is \alias(sub { $x })->(), \$x;

no warnings 'void';
alias copy alias copy $x = 99;
is \$x, \$z;
is $x, 99;

# vim: ft=perl

is \undef, scalar \alias
