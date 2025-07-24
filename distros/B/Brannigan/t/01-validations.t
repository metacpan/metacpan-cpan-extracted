#!/usr/bin/env perl

use lib './lib';
use strict;
use warnings;

use Test2::V0;
use Brannigan;

# required
is(
    Brannigan::process( { params => { one => { required => 1 } } }, {} ),
    { one => { required => 1 } },
    'required fails when value is not provided at all'
);
is(
    Brannigan::process(
        { params => { one => { required => 1 } } },
        { one    => '' }
    ),
    undef,
    'required succeeds when value is defined, even if empty string'
);
is(
    Brannigan::process(
        { params => { one => { required => 1 } } },
        { one    => 'asdf' }
    ),
    undef,
    'required succeeds when value is defined and not empty'
);

# is_true
is(
    Brannigan::process(
        { params => { one => { is_true => 1 } } },
        { one    => 2 }
    ),
    undef,
    'is_true succeeds when value is a non-zero number'
);
is(
    Brannigan::process(
        { params => { one => { is_true => 1 } } },
        { one    => 0 }
    ),
    { one => { is_true => 1 } },
    'is_true succeeds when value is zero',
);
is(
    Brannigan::process(
        { params => { one => { is_true => 1 } } },
        { one    => 'asdf' }
    ),
    undef,
    'is_true succeeds when value is a non-empty string'
);
is(
    Brannigan::process(
        { params => { one => { is_true => 1 } } },
        { one    => '' }
    ),
    { one => { is_true => 1 } },
    'is_true succeeds when value is an empty string'
);
is(
    Brannigan::process(
        { params => { one => { is_true => 0 } } },
        { one    => '' }
    ),
    undef,
    'is_true succeeds either case if boolean is false'
);

# length_between
is(
    Brannigan::process(
        { params => { one => { length_between => [ 1, 5 ] } } },
        { one    => 'asdf' },
    ),
    undef,
    'length_between succeeds when value is inside range'
);
is(
    Brannigan::process(
        { params => { one => { length_between => [ 4, 4 ] } } },
        { one    => 'asdf' },
    ),
    undef,
'length_between succeeds when range is exact and string is of the same length'
);
is(
    Brannigan::process(
        { params => { one => { length_between => [ 1, 3 ] } } },
        { one    => 'asdf' },
    ),
    { one => { length_between => [ 1, 3 ] } },
    'length_between fails when length is outside range (longer)'
);
is(
    Brannigan::process(
        { params => { one => { length_between => [ 5, 6 ] } } },
        { one    => 'asdf' },
    ),
    { one => { length_between => [ 5, 6 ] } },
    'length_between fails when length is outside range (shorter)'
);

# min_length (strings)
is(
    Brannigan::process(
        { params => { one => { min_length => 3 } } },
        { one    => 'asdf' },
    ),
    undef,
    'min_length succeeds when string is longer than minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_length => 4 } } },
        { one    => 'asdf' },
    ),
    undef,
    'min_length succeeds when string is exactly the minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_length => 5 } } },
        { one    => 'asdf' },
    ),
    { one => { min_length => 5 } },
    'min_length fails when string is shorter than minimum'
);

# max_length (strings)
is(
    Brannigan::process(
        { params => { one => { max_length => 5 } } },
        { one    => 'asdf' }
    ),
    undef,
    'max_length succeeds when string is shorter than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_length => 4 } } },
        { one    => 'asdf' }
    ),
    undef,
    'max_length succeeds when string is exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_length => 3 } } },
        { one    => 'asdf' }
    ),
    { one => { max_length => 3 } },
    'max_length fails when string is longer than maximum'
);

# exact_length (strings)
is(
    Brannigan::process(
        { params => { one => { exact_length => 4 } } },
        { one => 'asdf' }
    ),
    undef,
    'exact_length succeeds when string is exactly the required length'
);
is(
    Brannigan::process(
        { params => { one => { exact_length => 5 } } },
        { one => 'asdf' }
    ),
    { one => { exact_length => 5 } },
    'exact_length fails when string is shorter than required'
);
is(
    Brannigan::process(
        { params => { one => { exact_length => 3 } } },
        { one => 'asdf' }
    ),
    { one => { exact_length => 3 } },
    'exact_length fails when string is longer than required'
);

# exact_length (arrays)
is(
    Brannigan::process(
        { params => { one => { exact_length => 4 } } },
        { one => [ 1 .. 4 ] }
    ),
    undef,
    'exact_length succeeds when array has exactly the required length'
);
is(
    Brannigan::process(
        { params => { one => { exact_length => 5 } } },
        { one => [ 1 .. 4 ] }
    ),
    { one => { exact_length => 5 } },
    'exact_length fails when array is shorter than required'
);
is(
    Brannigan::process(
        { params => { one => { exact_length => 3 } } },
        { one => [ 1 .. 4 ] }
    ),
    { one => { exact_length => 3 } },
    'exact_length fails when array is longer than required'
);

# min_length (arrays)
is(
    Brannigan::process(
        { params => { one => { min_length => 3 } } },
        { one    => [ 1 .. 4 ] }
    ),
    undef,
    'min_length succeeds when array is longer than minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_length => 4 } } },
        { one    => [ 1 .. 4 ] }
    ),
    undef,
    'min_length succeeds when array is exactly the minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_length => 5 } } },
        { one    => [ 1 .. 4 ] }
    ),
    { one => { min_length => 5 } },
    'min_length fails when array is shorter than minimum'
);

# max_length (arrays)
is(
    Brannigan::process(
        { params => { one => { max_length => 5 } } },
        { one    => [ 1 .. 4 ] }
    ),
    undef,
    'max_length succeeds when array is shorter than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_length => 4 } } },
        { one    => [ 1 .. 4 ] }
    ),
    undef,
    'max_length succeeds when array is exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_length => 3 } } },
        { one    => [ 1 .. 4 ] }
    ),
    { one => { max_length => 3 } },
    'max_length fails when array is longer than maximum'
);

# integer
is(
    Brannigan::process(
        { params => { one => { integer => 1 } } },
        { one    => 1 }
    ),
    undef,
    'integer succeeds when value is an integer'
);
is(
    Brannigan::process(
        { params => { one => { integer => 1 } } },
        { one    => 0 }
    ),
    undef,
    'integer succeeds when value is zero'
);
is(
    Brannigan::process(
        { params => { one => { integer => 1 } } },
        { one    => 0.5 }
    ),
    { one => { integer => 1 } },
    'integer fails when value is a float'
);
is(
    Brannigan::process(
        { params => { one => { integer => 1 } } },
        { one    => "asdf" }
    ),
    { one => { integer => 1 } },
    'integer fails when value is a string',
);

# value_between
is(
    Brannigan::process(
        { params => { one => { value_between => [ 1, 5 ] } } },
        { one    => 3 }
    ),
    undef,
    'value_between succeeds when value is inside range'
);
is(
    Brannigan::process(
        { params => { one => { value_between => [ 4, 4 ] } } },
        { one    => 4 }
    ),
    undef,
    'value_between succeeds when range is exact and value is the same'
);
is(
    Brannigan::process(
        { params => { one => { value_between => [ 1, 3 ] } } },
        { one    => 4 },
    ),
    { one => { value_between => [ 1, 3 ] } },
    'value_between fails when value is outside range (higher)'
);
is(
    Brannigan::process(
        { params => { one => { value_between => [ 5, 7 ] } } },
        { one    => 4 },
    ),
    { one => { value_between => [ 5, 7 ] } },
    'value_between fails when value is outside range (lower)'
);

# min_value
is(
    Brannigan::process(
        { params => { one => { min_value => 3 } } },
        { one    => 4 }
    ),
    undef,
    'min_value succeeds when value is larger than minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_value => 4 } } },
        { one    => 4 }
    ),
    undef,
    'min_value succeeds when value is exactly the minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_value => 5 } } },
        { one    => 4 },
    ),
    { one => { min_value => 5 } },
    'min_value fails when value is lower than minimum'
);

# max_value
is(
    Brannigan::process(
        { params => { one => { max_value => 5 } } },
        { one    => 4 }
    ),
    undef,
    'max_value succeeds when value is lower than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_value => 4 } } },
        { one    => 4 }
    ),
    undef,
    'max_value succeeds when value is exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_value => 3 } } },
        { one    => 4 }
    ),
    { one => { max_value => 3 } },
    'max_value fails when value is larger than maximum'
);

# array
is(
    Brannigan::process(
        { params => { one => { array => 1 } } },
        { one => [ 1 .. 4 ] }
    ),
    undef,
    'array succeeds when value is an array'
);
is(
    Brannigan::process(
        { params => { one => { array => 1 } } },
        { one => { key => 'value' } }
    ),
    { one => { array => 1 } },
    'array fails when value is not an array (hash)'
);
is(
    Brannigan::process(
        { params => { one => { array => 1 } } },
        { one => 9 }
    ),
    { one => { array => 1 } },
    'array fails when value is not an array (integer)'
);

# hash
is(
    Brannigan::process(
        { params => { one => { hash => 1 } } },
        { one => { key => 'value' } }
    ),
    undef,
    'hash succeeds when value is a hash'
);
is(
    Brannigan::process(
        { params => { one => { hash => 1 } } },
        { one => [ 1 .. 4 ] }
    ),
    { one => { hash => 1 } },
    'hash fails when value is not a hash (array)'
);
is(
    Brannigan::process(
        { params => { one => { hash => 1 } } },
        { one => 9 }
    ),
    { one => { hash => 1 } },
    'hash fails when value is not a hash (integer)'
);

# one of
is(
    Brannigan::process(
        { params => { one => { one_of => [qw/one two asdf three/] } } },
        { one    => 'asdf' }
    ),
    undef,
    'one_of succeeds when value is in the array'
);
is(
    Brannigan::process(
        { params => { one => { one_of => [qw/one two three/] } } },
        { one    => 'asdf' }
    ),
    { one => { one_of => [ 'one', 'two', 'three' ] } },
    'one_of fails when value is not in the array'
);

# matches
is(
    Brannigan::process(
        { params => { one => { matches => qr/^asdf/ } } },
        { one    => 'asdfloqwer' }
    ),
    undef,
    'matches succeeds with a simple regex'
);
is(
    Brannigan::process(
        { params => { one => { matches => qr/^a\d{1,3}(s|m)\d+df$/ } } },
        { one    => 'a5s11df' }
    ),
    undef,
    'matches succeeds with a little more complex regex'
);
is(
    Brannigan::process(
        { params => { one => { matches => qr/chemical/ } } },
        { one    => 'asdf' }
    ),
    { one => { matches => qr/chemical/ } },
    'matches fails when value does not match regex'
);

# min_alpha
is(
    Brannigan::process(
        { params => { one => { min_alpha => 2 } } },
        { one => 'a098123l2T' }
    ),
    undef,
    'min_alpha succeeds when string has more than minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_alpha => 3 } } },
        { one => 'a098123l2T' }
    ),
    undef,
    'min_alpha succeeds when string has exactly the minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_alpha => 4 } } },
        { one => 'a098123l2T' }
    ),
    { one => { min_alpha => 4 } },
    'min_alpha fails when string has less than minimum'
);

# max_alpha
is(
    Brannigan::process(
        { params => { one => { max_alpha => 4 } } },
        { one => 'a098123l2T' }
    ),
    undef,
    'max_alpha succeeds when string has less than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_alpha => 3 } } },
        { one => 'a098123l2T' }
    ),
    undef,
    'max_alpha succeeds when string has exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_alpha => 2 } } },
        { one => 'a098123l2T' }
    ),
    { one => { max_alpha => 2 } },
    'max_alpha fails when string has more than maximum'
);

# min_digits
is(
    Brannigan::process(
        { params => { one => { min_digits => 2 } } },
        { one => 'a12bbtw9' }
    ),
    undef,
    'min_digits succeeds when string has more than minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_digits => 3 } } },
        { one => 'a12bbtw9' }
    ),
    undef,
    'min_digits succeeds when string has exactly the minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_digits => 4 } } },
        { one => 'a12bbtw9' }
    ),
    { one => { min_digits => 4 } },
    'min_digits fails when string has less than minimum'
);

# max_digits
is(
    Brannigan::process(
        { params => { one => { max_digits => 4 } } },
        { one => 'a12bbtw9' }
    ),
    undef,
    'max_digits succeeds when string has less than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_digits => 3 } } },
        { one => 'a12bbtw9' }
    ),
    undef,
    'max_digits succeeds when string has exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_digits => 2 } } },
        { one => 'a12bbtw9' }
    ),
    { one => { max_digits => 2 } },
    'max_digits fails when string has more than maximum'
);

# min_signs
is(
    Brannigan::process(
        { params => { one => { min_signs => 2 } } },
        { one => 'a!bl098$43#' }
    ),
    undef,
    'min_signs succeeds when string has more than minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_signs => 3 } } },
        { one => 'a!bl098$43#' }
    ),
    undef,
    'min_signs succeeds when string has exactly the minimum'
);
is(
    Brannigan::process(
        { params => { one => { min_signs => 4 } } },
        { one => 'a!bl098$43#' }
    ),
    { one => { min_signs => 4 } },
    'min_signs fails when string has less than minimum'
);

# max_signs
is(
    Brannigan::process(
        { params => { one => { max_signs => 4 } } },
        { one => 'a!bl098$43#' }
    ),
    undef,
    'max_signs succeeds when string has less than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_signs => 3 } } },
        { one => 'a!bl098$43#' }
    ),
    undef,
    'max_signs succeeds when string has exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_signs => 2 } } },
        { one => 'a!bl098$43#' }
    ),
    { one => { max_signs => 2 } },
    'max_signs fails when string has more than maximum'
);

# max_consec
is(
    Brannigan::process(
        { params => { one => { max_consec => 5 } } },
        { one => 'a!$bcde' }
    ),
    undef,
    'max_consec succeeds when a string sequence is less than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_consec => 5 } } },
        { one => 'a!$1234' }
    ),
    undef,
    'max_consec succeeds when a numeric sequence is less than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_consec => 4 } } },
        { one => 'a!$bcde' }
    ),
    undef,
    'max_consec succeeds when a string sequence is exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_consec => 4 } } },
        { one => 'a!$1234' }
    ),
    undef,
    'max_consec succeeds when a numeric sequence is exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_consec => 3 } } },
        { one => 'a!$bcde' }
    ),
    { one => { max_consec => 3 } },
    'max_consec fails when a string sequence is more than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_consec => 3 } } },
        { one => 'a!$1234' }
    ),
    { one => { max_consec => 3 } },
    'max_consec fails when a numeric sequence is more than maximum'
);

# max_reps
is(
    Brannigan::process(
        { params => { one => { max_reps => 5 } } },
        { one => 'a!$bbbb' }
    ),
    undef,
    'max_reps succeeds when a string sequence is less than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_reps => 5 } } },
        { one => 'a!$1111' }
    ),
    undef,
    'max_reps succeeds when a numeric sequence is less than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_reps => 4 } } },
        { one => 'a!$bbbb' }
    ),
    undef,
    'max_reps succeeds when a string sequence is exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_reps => 4 } } },
        { one => 'a!$1111' }
    ),
    undef,
    'max_reps succeeds when a numeric sequence is exactly the maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_reps => 3 } } },
        { one => 'a!$bbbb' }
    ),
    { one => { max_reps => 3 } },
    'max_reps fails when a string sequence is more than maximum'
);
is(
    Brannigan::process(
        { params => { one => { max_reps => 3 } } },
        { one => 'a!$1111' }
    ),
    { one => { max_reps => 3 } },
    'max_reps fails when a numeric sequence is more than maximum'
);

done_testing();
