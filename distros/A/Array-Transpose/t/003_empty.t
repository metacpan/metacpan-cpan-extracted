# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 2;
use Array::Transpose;
my @in=();
my $out=transpose(\@in);
is(scalar(@$out), 0, 'Scalar Context');

my @out=transpose(\@in);
is(scalar(@out), 0, 'Scalar Context');
