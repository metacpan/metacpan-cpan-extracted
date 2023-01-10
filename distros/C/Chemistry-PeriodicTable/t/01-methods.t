#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Chemistry::PeriodicTable';

my $obj = new_ok 'Chemistry::PeriodicTable';

my $got = $obj->as_file;
ok -e $got, 'as_file';

my @headers = $obj->headers;
is @headers, 21, 'headers';
is_deeply \@headers, $obj->header, 'header';

$got = $obj->as_hash;
is_deeply [ @{ $got->{H} }[0,1] ], [1, 'Hydrogen'], 'as_hash';

is_deeply $got, $obj->data, 'data';

is $obj->atomic_number('H'), 1, 'atomic_number';
is $obj->atomic_number('hydrogen'), 1, 'atomic_number';

is $obj->name(1), 'Hydrogen', 'name';
is $obj->name('H'), 'Hydrogen', 'name';

is $obj->symbol(1), 'H', 'symbol';
is $obj->symbol('hydrogen'), 'H', 'symbol';

is $obj->value('H', 'weight'), 1.00794, 'weight';
is $obj->value(118, 'weight'), 294, 'weight';
is $obj->value('hydrogen', 'Atomic Radius'), 0.79, 'Atomic Radius';

done_testing();
