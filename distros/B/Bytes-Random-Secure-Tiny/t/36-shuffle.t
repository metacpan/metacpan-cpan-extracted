#!/usr/bin/env perl

use strict;
use warnings;
use Bytes::Random::Secure::Tiny;
use List::Util qw(max min);
use Test::More;

my $r = Bytes::Random::Secure::Tiny->new;
isa_ok $r, 'Bytes::Random::Secure::Tiny';

my @array = 1..16;

my @ranged = map {$r->_ranged_randoms(scalar @array, 1)->[0]} 1 .. 10000;
is min(@ranged), 0, 'Minimum ranged is zero.';
is max(@ranged), 15, 'Maximum ranged is fifteen.';

my $aref = $r->shuffle([@array]);
cmp_ok ref $aref, 'eq', 'ARRAY', 'shuffle returns an aref.';
cmp_ok scalar @$aref, '==', 16, 
    'in sitiu shuffle returned correct element count.';

is min(@$aref), 1, 'shuffle returned correct min value.';
is max(@$aref), 16, 'shuffle returned correct max value.';
my %found;
@found{@$aref} = ();
is scalar keys %found, 16, 'All elements received after shuffle.';
ok((0 != grep { $array[$_] != $aref->[$_] } 0 .. 15),
    'Elements are in different order from original.');

my $res = eval {$r->shuffle(@array)} || $@;
like $res, qr/Argument must be an array reference\./,
     'shuffle dies unless passed an array reference.';


done_testing();

