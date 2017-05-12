#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;
use Scalar::Util qw(reftype);

use Class::Ref;

my @array = (['foobar']);

my $obj = Class::Ref->new(\@array);

isa_ok $obj, 'Class::Ref::ARRAY', 'blessed into ARRAY wrapper';

is reftype $obj, 'REF', 'blessed ref is correct type';

is_deeply $$obj, \@array, 'inner ref is correct';

isa_ok $obj->[0], 'Class::Ref::ARRAY', 'deep array blessed';

isa_ok tied(@{$obj->[0]}), 'Class::Ref::ARRAY::Tie', 'deep array tied';

is_deeply ${$obj->[0]}, $array[0], 'deep ARRAY preserved';

{
    local $Class::Ref::raw_access = 1;
    is_deeply $obj->[0], $array[0], 'raw access enabled';
}

is $obj->[0]->[0], 'foobar', 'deep wrapping access';
