#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;
use Scalar::Util qw(reftype);

use Class::Ref;

my %hash = (foo => { bar => 42 });

my $obj = Class::Ref->new(\%hash);

isa_ok $obj, 'Class::Ref::HASH', 'blessed into HASH wrapper';

is reftype $obj, 'REF', 'blessed ref is correct type';

is_deeply $$obj, \%hash, 'inner ref is correct';

isa_ok $obj->foo, 'Class::Ref::HASH', 'deep hash blessed';

isa_ok tied(%{$obj->foo}), 'Class::Ref::HASH::Tie', 'deep hash tied';

is_deeply ${$obj->foo}, $hash{foo}, 'deep HASH preserved';

{
    local $Class::Ref::raw_access = 1;
    is_deeply $obj->foo, $hash{foo}, 'raw access enabled';
}

is $obj->foo->bar, 42, 'deep wrapping access';
