#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 2;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

$v->put_goldbach_g1(0 .. 257);
$v->rewind_for_read;
is_deeply( [$v->get_goldbach_g1(-1)], [0 .. 257], 'Goldbach G1 0-257');

$v->erase_for_write;

$v->put_goldbach_g2(0 .. 257);
$v->rewind_for_read;
is_deeply( [$v->get_goldbach_g2(-1)], [0 .. 257], 'Goldbach G2 0-257');
