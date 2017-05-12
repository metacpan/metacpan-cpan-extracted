#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 6;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

$v->put_unary(0 .. 257);

$v->rewind_for_read;

my $a;
my @a;

$a = $v->get_unary(0);
is($a, undef, 'get_unary_array into scalar with count = 0');
@a = $v->get_unary(0);
is_deeply(\@a, [], 'get_unary_array into array with count = 0');

$a = $v->get_unary(2);
is($a, 1, 'get_unary_array into scalar with count > 0');

$a = $v->get_unary;
is($a, 2, 'get_unary_array into scalar with implied count 1');

@a = $v->get_unary(3);
is_deeply( [@a], [3,4,5], 'get_unary_array into array with count > 0');

@a = $v->get_unary(-1);
is_deeply( [@a], [6 .. 257], 'get_unary_array into array with count -1');
