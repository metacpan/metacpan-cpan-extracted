use strict;
use warnings;
use File::Spec::Functions;
use lib "local/lib/perl5";

use Test::More 0.98;
use Test::Deep;

use Data::WeakMap;
use Scalar::Util 'isweak', 'refaddr';

plan tests => 9;

sub create_map {
    my $map = Data::WeakMap->new;
    my $struct = ${ tied(%$map)->[0] };
    my $keys = $struct->{tied_keys};
    my $values = $struct->{values};
    isa_ok($map, 'Data::WeakMap', 'new WeakMap');
    is(ref $struct, 'HASH', 'underlying object is a hashref');
    return ($map, $keys, $values);
}


subtest 'store & retrieve key/value pair' => sub {
    plan tests => 12;

    my ($map, $keys, $values) = create_map;

    my $key1 = [ 'foo', 123 ];
    my $key2 = { foo => 123 };
    my $key3 = [ 10 ];

    $map->{$key1} = 5;
    is(keys(%$map), 1, 'weakmap has exactly one key');
    is(keys(%$keys), 1, 'underlying structure has exactly one key');
    is(keys(%$values), 1, 'underlying structure has exactly one key (values)');

    $map->{$key2} = 10;
    is(keys(%$map), 2, 'weakmap has exactly two keys');
    is(keys(%$keys), 2, 'underlying structure has exactly two keys');
    is(keys(%$values), 2, 'underlying structure has exactly two keys (values)');

    is($map->{$key1}, 5, 'fetch WeakMap value for first key');
    is($map->{$key2}, 10, 'fetch WeakMap value for second key');
    is($map->{$key3}, undef, 'fetch WeakMap value for third, non-existent, key');

    check_under_weakness($keys);
};

subtest 'key/value pairs get deleted when key falls out of scope' => sub {
    plan tests => 12;

    my ($map, $keys, $values) = create_map;

    my $key1 = [ 'foo', 123 ];
    $map->{$key1} = 5;
    is(keys(%$map), 1, 'store first key/value');
    is(keys(%$keys), 1, 'store first key/value');
    is(keys(%$values), 1, 'store first key/value');

    {
        my $key2 = { foo => 123 };
        $map->{$key2} = 10;
        is(keys(%$map), 2, 'store second key/value');
        is(keys(%$keys), 2, 'store second key/value');
        is(keys(%$values), 2, 'store second key/value');
    }

    is(keys(%$map), 1, 'one element again');
    is(keys(%$keys), 1, 'one element again');
    is(keys(%$values), 1, 'one element again');

    check_under_weakness($keys);
};

subtest 'full iteration (e.g. "keys %$map", "values %$map", "%$map") attempt' => sub {
    plan tests => 9;

    my ($map, $keys, $values) = create_map;

    {
        note 'in the block scope now... setting 3 scoped lexical keys to %$map';
        my @input_keys = ([10], [20], [30]);
        $map->{$_} = $_->[0] * 10 foreach @input_keys;

        is_deeply([map refaddr($_), sort @input_keys], [map refaddr($_), sort keys %$map], 'keys function returns the correct keys (numeric)');

        cmp_deeply([100, 200, 300], bag(values %$map), 'values function returns the correct values');

        cmp_deeply([%$map], bag(@input_keys, 100, 200, 300), '%$map returns the correct 6 items');

        check_under_weakness($keys);
    }
    note 'block scope finished';
    is(keys(%$map), 0, 'map has lost its keys');
    is(keys(%$keys), 0, 'map has lost its keys');
    is(keys(%$values), 0, 'map has lost its keys');
};

subtest 'delete keys' => sub {
    plan tests => 9;

    my ($map, $keys, $values) = create_map;

    my @input_keys = ([10], [20], [30]);
    $map->{$_} = $_->[0] * 10 foreach @input_keys;

    is(keys(%$map), 3, '%$map has 3 keys before delete');

    my $ret = delete $map->{$input_keys[1]};
    is($ret, 200, 'delete returned the correct value');

    cmp_deeply([map refaddr($_), keys %$map], bag(map refaddr($_), @input_keys[0, 2]), 'correct 2 keys remain');
    is(keys(%$map), 2, 'map has 2 keys');
    is(keys(%$keys), 2, 'map has 2 keys');
    is(keys(%$values), 2, 'map has 2 keys');

    check_under_weakness($keys);
};

subtest 'exists' => sub {
    plan tests => 9;

    my ($map, $keys, $values) = create_map;

    my @input_keys = map { [$_ * 10] } (1 .. 100);
    @$map{@input_keys} = (201 .. 300);

    is(keys(%$map), 100, '%$map has 100 key/value pairs');

    ok(exists $map->{$input_keys[50]}, '50th input still exists');
    check_under_weakness($keys);
    is(keys(%$map), 100, '%map still has all 100 key/value pairs');

    my $foreign_object = [50];
    ok(! exists $map->{$foreign_object}, 'new foreign object does not exist');
    check_under_weakness($keys);
    is(keys(%$map), 100, '%map still has all of its 100 key/value pairs');
};

subtest 'scalar' => sub {
    plan tests => 3;

    my ($map, $keys, $values) = create_map;

    my @input_keys = map { [$_ * 10] } (1 .. 100);
    @$map{@input_keys} = (201 .. 300);


    my $scalar_values = scalar(%$values);
    is(scalar(%$map), $scalar_values, 'scalar(map) returns the same as an internal hashref of the same size');
};

subtest 'boolean' => sub {
    plan tests => 6;
    # TODO: skip, if perl is not recent enough (see perltie, and how it handles SCALAR when evaluating keys(%$map) in boolean context)

    my ($map, $keys, $values) = create_map;

    ok((keys %$map) ? 0 : 1, '(keys %$map) in boolean context == 0, when empty');
    ok((%$map) ? 0 : 1,      '(%$map) in boolean context == 0, when empty');

    my @input_keys = map { [$_ * 10] } (1 .. 10);
    @$map{@input_keys} = (201 .. 210);

    ok((keys %$map) ? 1 : 0, '(keys %$map) in boolean context == 1, when non-empty');
    ok((%$map) ? 1 : 0,      '(%$map) in boolean context == 1, when non-empty');
};

TODO: {
    local $TODO = "can't do it now, because the each function will automatically unweaken the keys for some reason";

    subtest 'attempt to do partial iteration with "each"' => sub {
        plan tests => 5;

        my ($map, $keys, $values) = create_map;

        {
            my @keys1 = ([ 10 ], [ 20 ], [ 30 ]);
            $map->{$_} = 100 foreach @keys1;
            is(keys(%$map), 3, 'map has 3 scoped lexical elements');
            note "calling the 'each' function twice";
            my @key_value_pairs = map { [each %$map] } (1 .. 2);
        }
        check_under_weakness($keys);
        is(keys(%$map), 0, 'map has 0 keys, it lost them when they went out of scope');
    };
}

subtest 'clear' => sub {
    plan tests => 4;

    my ($map, $keys, $values) = create_map;

    my @keys_values = map { [] } (1 .. 10);

    %$map = @keys_values[0 .. 9];
    is(keys %$keys, 5, 'there are 5 keys in the underlying hash');

    %$map = @keys_values[0 .. 5];
    is(keys %$keys, 3, 'there are 3 keys in the underlying hash');
};


sub check_under_weakness {
    my ($keys) = @_;

    my $total_count = keys %$keys;
    my $strong_count = 0;
    foreach my $key (values %$keys) {
        $strong_count++ unless isweak $key;
    }

    if ($strong_count == 0) {
        pass "all $total_count keys in underlying object are still weak refs";
    } else {
        fail "$strong_count keys (out of $total_count) in the underlying object have been unweakened";
    }
}
