use strict;
use warnings qw(FATAL all);
no warnings 'void';
use lib 'lib';
use Test::More tests => 4;

use Data::Alias;

our $x = "x";
my $xref = "@{[\$x]}";
our $y = "y";
my $yref = "@{[\$y]}";
alias { ($x, $y) = ($y, $x) };
is $x, "y";
is $y, "x";
is "@{[\$x]}", $yref;
is "@{[\$y]}", $xref;

1;
