#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 1;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

$v->put_unary1(0 .. 257);
$v->rewind_for_read;
is_deeply( [$v->get_unary1(-1)], [0 .. 257], 'unary1 0-257');
