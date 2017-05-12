#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Scalar::Util qw(reftype);

use Class::Ref;

my %hash = (foo => ['bar']);

my $obj = Class::Ref->new(\%hash);

isa_ok $obj, 'Class::Ref::HASH', 'blessed into HASH wrapper';

is reftype $obj, 'REF', 'blessed ref is correct type';

is_deeply $$obj, \%hash, 'inner ref is correct';

isa_ok $obj->foo, 'Class::Ref::ARRAY', 'deep array blessed';

isa_ok tied(@{$obj->foo}), 'Class::Ref::ARRAY::Tie', 'deep array tied';

is_deeply ${$obj->foo}, $hash{foo}, 'deep ARRAY preserved';

is $obj->foo->[0], 'bar', 'deep wrapping access';
