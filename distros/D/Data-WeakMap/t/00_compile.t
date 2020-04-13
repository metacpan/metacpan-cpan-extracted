use v5.14; # remove this
use strict;
use warnings;
use Test::More 0.98;

use Data::WeakMap;

use Scalar::Util 'isweak';

subtest 'store & retrieve key/value pair' => sub {
    plan tests => 7;

    my $map = new_ok('Data::WeakMap', [], 'new WeakMap');
    isa_ok(my $under = tied(%$map), 'Data::WeakMap::Tie', 'underlying object');

    my $key1 = [ 'foo', 123 ];
    my $key2 = { foo => 123 };
    my $key3 = [ 10 ];

    $map->{$key1} = 5;
    is(keys(%$under), 1, 'underlying structure has exactly one key');

    $map->{$key2} = 10;
    is(keys(%$under), 2, 'underlying structure has exactly two keys');

    is($map->{$key1}, 5, 'fetch WeakMap value for first key');
    is($map->{$key2}, 10, 'fetch WeakMap value for second key');
    is($map->{$key3}, undef, 'fetch WeakMap value for third, non-existent, key');
};

subtest 'key/value pairs get deleted when key falls out of scope' => sub {
    plan tests => 6;

    my $map = new_ok('Data::WeakMap', [], 'new WeakMap');
    isa_ok(my $under = tied(%$map), 'Data::WeakMap::Tie', 'underlying object');

    my $key1 = [ 'foo', 123 ];
    $map->{$key1} = 5;
    is(keys(%$under), 1, 'store first key/value');

    {
        my $key2 = { foo => 123 };
        $map->{$key2} = 10;
        is(keys(%$under), 2, 'store second key/value');
    }

    check_under_weakness($under);

    is(keys(%$under), 1, 'key/value gets deleted when key falls out of scope');
};

subtest 'full iteration (e.g. "keys %$map", "values %$map", "%$map") attempt' => sub {
    plan tests => 10;

    my $map = new_ok('Data::WeakMap', [], 'new WeakMap');
    isa_ok(my $under = tied(%$map), 'Data::WeakMap::Tie', 'underlying object');

    {
        note 'in the block scope now... setting 3 scoped lexical keys to %$map';
        my @input_keys = ([10], [20], [30]);
        $map->{$_} = $_->[0] * 10 foreach @input_keys;

        my @keys = keys %$map;
        is(@keys, 3, 'map has 3 keys');
        @keys = sort {$a->[0] <=> $b->[0]} @keys;

        subtest '"keys %$map" (sorted) returns the 3 inserted keys' => sub {
            is($keys[$_], $input_keys[$_], "key $_ identical") foreach (0..2);
        };

        my @values = values %$map;
        is(@values, 3, 'values %$map returns 3 values');
        @values = @$map{@keys};
        is_deeply(\@values, [100, 200, 300], '@$map{@keys} returns the expected values');
        my @everything = %$map;
        is(@everything, 6, '%$map in list context returns 6 values');
        check_under_weakness($under);
    }
    note 'block scope finished';
    is(keys(%$map), 0, 'map has lost its keys');
    my @everything_under = %$under;
    is(scalar(@everything_under), 0, 'underlying object is completely empty, too');
};

subtest 'delete keys' => sub {
    plan tests => 6;

    my $map = new_ok('Data::WeakMap', [], 'new WeakMap');
    isa_ok(my $under = tied(%$map), 'Data::WeakMap::Tie', 'underlying object');

    my @input_keys = ([10], [20], [30]);
    $map->{$_} = $_->[0] * 10 foreach @input_keys;

    is(keys(%$map), 3, '%$map has 3 keys before delete');
    delete $map->{$input_keys[1]};
    is(keys(%$map), 2, '%$map has 2 keys after delete');
    is(keys(%$under), 2, 'underlying object also has 2 keys');

    check_under_weakness($under);
};

subtest 'exists' => sub {
    plan tests => 9;

    my $map = new_ok('Data::WeakMap', [], 'new WeakMap');
    isa_ok(my $under = tied(%$map), 'Data::WeakMap::Tie', 'underlying object');

    my @input_keys = map { [$_ * 10] } (1 .. 100);
    @$map{@input_keys} = (201 .. 300);

    is(keys(%$map), 100, '%map has 100 key/value pairs');

    ok(exists $map->{$input_keys[50]}, '50th input still exists');
    check_under_weakness($under);
    is(keys(%$map), 100, '%map still has all 100 key/value pairs');

    my $foreign_object = [50];
    ok(! exists $map->{$foreign_object}, 'new foreign object does not exist');
    check_under_weakness($under);
    is(keys(%$map), 100, '%map still has all of its 100 key/value pairs');
};

TODO: {
    local $TODO = "can't do it now, because the each function will automatically unweaken the keys for some reason";

    subtest 'attempt to do partial iteration with "each"' => sub {
        plan tests => 4;

        my $map = new_ok('Data::WeakMap', [], 'new WeakMap');
        isa_ok(my $under = tied(%$map), 'Data::WeakMap::Tie', 'underlying object');

        {
            my @keys1 = ([ 10 ], [ 20 ], [ 30 ]);
            $map->{$_} = 100 foreach @keys1;
            is(keys(%$map), 3, 'map has 3 scoped lexical elements');
            note "calling the 'each' function twice";
            my @key_value_pairs = map { [each %$map] } (1 .. 2);
        }

        is(keys(%$map), 0, 'map loses its keys, when they go out of scope');
    };
}

done_testing;

# a custom test

sub check_under_weakness {
    my ($under) = @_;

    my $total_count = keys %$under;
    my $strong_count = 0;
    foreach my $value (values %$under) {
        $strong_count++ unless isweak ${ $value->{ref_c} };
    }

    if (! $strong_count) {
        pass "all $total_count keys in underlying object are still weak refs";
    } else {
        fail "$strong_count keys (out of $total_count) in the underlying object have been unweakened";
    }
}
