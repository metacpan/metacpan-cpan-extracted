#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 27;
use Scalar::Util qw(reftype);

use Class::Ref;

# for AUTOLOAD testing
sub FOOBAR ()   { 0 }
sub AUTOLOAD () { 1 }
sub BAZ ()      { 3 }
sub TOOBIG ()   { 100 }
sub STRING ()   { 'foobar' }

my @array = ('foo', 'bar');

my $obj = Class::Ref->new(\@array);

isa_ok $obj, 'Class::Ref::ARRAY', 'blessed into ARRAY wrapper';

isa_ok tied(@$obj), 'Class::Ref::ARRAY::Tie';

is reftype $obj, 'REF', 'blessed ref is correct type';

is_deeply $$obj, \@array, 'inner ref is correct';

is $obj->[0], 'foo', 'FETCH values';

cmp_ok push(@$obj, 'baz'), '==', 3, 'push added correct amount';

$obj->[4] = 'foobar';
is $obj->[4], 'foobar', 'assigned new value';

is splice(@$obj, 2, 1), 'baz', 'splice';
is $obj->[3], 'foobar', 'index shift';

is pop(@$obj), 'foobar', 'tied pop operator';
push @$obj, 'foobar';
is $obj->[3], 'foobar', 'tied push operator';

is shift(@$obj), 'foo', 'tied shift operator';
unshift @$obj, 'foo';
is $obj->[0], 'foo', 'tied unshift operator';

is delete($obj->[3]), 'foobar', 'tied delete operator';
ok !exists($obj->[3]), 'tied exists operator';

is $obj->FOOBAR, 'foo', 'AUTOLOAD index';

is $obj->AUTOLOAD, 'bar', 'ATUOLOAD access';

$obj->FOOBAR('baz');
is $obj->FOOBAR, 'baz', 'AUTOLOAD assign';

eval { $obj->FOO };
like $@, qr/'FOO' is not a numeric constant in 'main'/, 'non-existent constant';

eval { $obj->STRING };
like $@, qr/'STRING' is not a numeric constant in 'main'/, 'non-numeric constant';

ok !defined($obj->TOOBIG), 'existent, yet undef';

$obj->BAZ('baz');
is $obj->BAZ, 'baz', 'non-existent, create';

is $obj->index(0), 'baz', 'index method';

eval { $obj->index };
like $@, qr/No index given/, 'no index guard';

my $itr = $obj->iterator;
is $itr->(), 'baz', 'iterator';

@$obj = ();
ok @$obj == 0, 'tied clear operator';

$#$obj = 5;
ok @$obj == 6, 'tied STORESIZE';


