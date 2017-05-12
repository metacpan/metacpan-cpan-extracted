#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 6;

require_ok 'Data::BitStream::XS';

can_ok('Data::BitStream::XS' => 'new');

#my $v = new_ok('Data::BitStream::XS');
my $v = Data::BitStream::XS->new;
isa_ok $v, 'Data::BitStream::XS';

is($v->len, 0, 'starting len 0');
is($v->pos, 0, 'starting pos 0');
cmp_ok($v->maxlen, '>=', 0, 'starting maxlen is >= 0');

$v->write(10, 5);

#done_testing;
