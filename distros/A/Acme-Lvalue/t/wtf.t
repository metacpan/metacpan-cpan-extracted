#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 3;

use Acme::Lvalue [succ => sub { $_[0] + 1 }, sub { $_[0] - 1 }], qw(:builtins);

my $x;
succ(succ($x)) = 4;
is $x, 2;

length(sqrt($x)) = 5;
is $x, '1.999396';

reverse(hex $x) = '9558295373';
is $x, 'deadbeef';
