#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 20;

use Data::Alias;

sub refs { [map "".\$_, @_] }

our $x = alias {};
is %$x, 0;

is_deeply alias({$_, 0}), {$_, 0}  for 1 .. 3;

$x = alias {x => 42};
eval { $x->{x}++ };
like $@, qr/^Modification .* attempted /;

$x = alias {x => $x};
is_deeply [sort keys %$x], ["x"];
is_deeply refs($$x{x}), refs($x);

$x = alias {x => $x, y => our $y};
is_deeply [sort keys %$x], ["x", "y"];
is_deeply refs(@$x{"x", "y"}), refs($x, $y);

$x = alias {x => $x, y => $y, z => our $z};
is_deeply [sort keys %$x], ["x", "y", "z"];
is_deeply refs(@$x{"x", "y", "z"}), refs($x, $y, $z);

$x = alias {x => 1, x => 2, x => 3};
is $x->{x}, 3;

$x = alias {x => undef, y => $y, z => undef};
is keys %$x, 1;
is \$x->{y}, \$y;
ok !exists $x->{x};
ok !exists $x->{z};

no warnings 'misc';

$x = alias {x => $x, y => $y, y => };
is keys %$x, 1;
is \$x->{x}, \$x;

use warnings qw(FATAL misc);

$x = eval { alias {x => $x, y => } };
is $x, undef;
like $@, qr/^Odd number of elements in anonymous hash /;

# vim: ft=perl
