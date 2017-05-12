#!perl -T

use strict;
use warnings;
use Test::More tests => 80;
use Brannigan::Validations;

# required
ok(!Brannigan::Validations->required(undef, 1), 'required fails when value is undefined');
ok(Brannigan::Validations->required('', 1), 'required succeeds when value is defined yet uninitialized');
ok(Brannigan::Validations->required('asdf', 1), 'required succeeds when value is defined and initialized');

# forbidden
ok(Brannigan::Validations->forbidden(undef, 1), 'forbidden succeeds when value is undefined');
ok(!Brannigan::Validations->forbidden('asdf', 1), 'forbidden fails when value is defined');

# is_true
ok(Brannigan::Validations->is_true(1, 1), 'is_true succeeds when value is a non-zero number');
ok(Brannigan::Validations->is_true('asdf', 1), 'is_true succeeds when value is a string');
ok(!Brannigan::Validations->is_true(0, 1), 'is_true fails when value is zero');
ok(!Brannigan::Validations->is_true('', 1), 'is_true fails when value is an empty string');
ok(Brannigan::Validations->is_true('', 0), 'is_true succeds either case if boolean is false');

# length_between
ok(Brannigan::Validations->length_between('asdf', 1, 5), 'length_between succeeds when value is inside range');
ok(Brannigan::Validations->length_between('asdf', 4, 4), 'length_between succeeds when range is exact and string is of the same length');
ok(!Brannigan::Validations->length_between('asdf', 1, 3), 'length_between fails when length is after range');
ok(!Brannigan::Validations->length_between('asdf', 5, 7), 'length_between fails when length is before range');

# min_length (strings)
ok(Brannigan::Validations->min_length('asdf', 3), 'min_length succeeds when string is longer than minimum');
ok(Brannigan::Validations->min_length('asdf', 4), 'min_length succeeds when string is exactly the minimum');
ok(!Brannigan::Validations->min_length('asdf', 5), 'min_length fails when string is shorter than minimum');

# max_length (strings)
ok(Brannigan::Validations->max_length('asdf', 5), 'max_length succeeds when string is shorter than maximum');
ok(Brannigan::Validations->max_length('asdf', 4), 'max_length succeeds when string is exactly the maximum');
ok(!Brannigan::Validations->max_length('asdf', 3), 'max_length fails when string is longer than maximum');

# min_length (arrays)
ok(Brannigan::Validations->min_length([1 .. 4], 3), 'min_length succeeds when array is longer than minimum');
ok(Brannigan::Validations->min_length([1 .. 4], 4), 'min_length succeeds when array is exactly the minimum');
ok(!Brannigan::Validations->min_length([1 .. 4], 5), 'min_length fails when array is shorter than minimum');

# max_length (arrays)
ok(Brannigan::Validations->max_length([1 .. 4], 5), 'max_length succeeds when array is shorter than maximum');
ok(Brannigan::Validations->max_length([1 .. 4], 4), 'max_length succeeds when array is exactly the maximum');
ok(!Brannigan::Validations->max_length([1 .. 4], 3), 'max_length fails when array is longer than maximum');

# integer
ok(Brannigan::Validations->integer(1, 1), 'integer succeeds when value is an integer');
ok(Brannigan::Validations->integer(0, 1), 'integer succeeds when value is zero');
ok(!Brannigan::Validations->integer(0.5, 1), 'integer fails when value is not an integer');

# value_between
ok(Brannigan::Validations->value_between(3, 1, 5), 'value_between succeeds when value is inside range');
ok(Brannigan::Validations->value_between(4, 4, 4), 'value_between succeeds when range is exact and value is the same');
ok(!Brannigan::Validations->value_between(4, 1, 3), 'value_between fails when value is after range');
ok(!Brannigan::Validations->value_between(4, 5, 7), 'value_between fails when value is before range');

# min_value
ok(Brannigan::Validations->min_value(4, 3), 'min_value succeeds when value is larger than minimum');
ok(Brannigan::Validations->min_value(4, 4), 'min_value succeeds when value is exactly the minimum');
ok(!Brannigan::Validations->min_value(4, 5), 'min_value fails when value is lower than minimum');

# max_value
ok(Brannigan::Validations->max_value(4, 5), 'max_value succeeds when value is lower than maximum');
ok(Brannigan::Validations->max_value(4, 4), 'max_value succeeds when value is exactly the maximum');
ok(!Brannigan::Validations->max_value(4, 3), 'max_value fails when value is larger than maximum');

# array
ok(Brannigan::Validations->array([1 .. 4], 1), 'array succeeds when value is an array');
ok(!Brannigan::Validations->array({ key => 'value' }, 1), 'array fails when value is not an array (hash)');
ok(!Brannigan::Validations->array(9, 1), 'array fails when value is not an array (integer)');

# hash
ok(Brannigan::Validations->hash({ key => 'value' }, 1), 'hash succeeds when value is an hash');
ok(!Brannigan::Validations->hash([1 .. 4], 1), 'hash fails when value is not an hash (array)');
ok(!Brannigan::Validations->hash(9, 1), 'hash fails when value is not an hash (integer)');

# one of
ok(Brannigan::Validations->one_of('asdf', qw/one two asdf three/), 'one_of succeeds when value is in the array');
ok(!Brannigan::Validations->one_of('asdf', qw/one two three/), 'one_of fails when value is not in the array');

# matches
ok(Brannigan::Validations->matches('asdfloqwer', qr/^asdf/), 'matches succeeds with a simple regex');
ok(Brannigan::Validations->matches('a5s11df', qr/^a\d{1,3}(s|m)\d+df$/), 'matches succeeds with a little more complex regex');
ok(!Brannigan::Validations->matches('asdf', qr/chemical/), 'matches fails when value does not match regex');

# min_alpha
ok(Brannigan::Validations->min_alpha('a098123l2T', 2), 'min_alpha succeeds when string has more than minimum');
ok(Brannigan::Validations->min_alpha('a098123l2T', 3), 'min_alpha succeeds when string has exactly the minimum');
ok(!Brannigan::Validations->min_alpha('a098123l2T', 4), 'min_alpha fails when string has less than minimum');

# max_alpha
ok(Brannigan::Validations->max_alpha('a098123l2T', 4), 'max_alpha succeeds when string has less than maximum');
ok(Brannigan::Validations->max_alpha('a098123l2T', 3), 'max_alpha succeeds when string has exactly the maximum');
ok(!Brannigan::Validations->max_alpha('a098123l2T', 2), 'max_alpha fails when string has more than maximum');

# min_digits
ok(Brannigan::Validations->min_digits('a12bbtw9', 2), 'min_digits succeeds when string has more than minimum');
ok(Brannigan::Validations->min_digits('a12bbtw9', 3), 'min_digits succeeds when string has exactly the minimum');
ok(!Brannigan::Validations->min_digits('a12bbtw9', 4), 'min_digits fails when string has less than minimum');

# max_digits
ok(Brannigan::Validations->max_digits('a12bbtw9', 4), 'max_digits succeeds when string has less than maximum');
ok(Brannigan::Validations->max_digits('a12bbtw9', 3), 'max_digits succeeds when string has exactly the maximum');
ok(!Brannigan::Validations->max_digits('a12bbtw9', 2), 'max_digits fails when string has more than maximum');

# min_signs
ok(Brannigan::Validations->min_signs('a!bl098$43#', 2), 'min_signs succeeds when string has more than minimum');
ok(Brannigan::Validations->min_signs('a!bl098$43#', 3), 'min_signs succeeds when string has exactly the minimum');
ok(!Brannigan::Validations->min_signs('a!bl098$43#', 4), 'min_signs fails when string has less than minimum');

# max_signs
ok(Brannigan::Validations->max_signs('a!bl098$43#', 4), 'max_signs succeeds when string has less than maximum');
ok(Brannigan::Validations->max_signs('a!bl098$43#', 3), 'max_signs succeeds when string has exactly the maximum');
ok(!Brannigan::Validations->max_signs('a!bl098$43#', 2), 'max_signs fails when string has more than maximum');

# max_consec
ok(Brannigan::Validations->max_consec('a!$bcde', 5), 'max_consec succeeds when a string sequence is less than maximum');
ok(Brannigan::Validations->max_consec('a!$1234', 5), 'max_consec succeeds when a numeric sequence is less than maximum');
ok(Brannigan::Validations->max_consec('a!$bcde', 4), 'max_consec succeeds when a string sequence is exactly than maximum');
ok(Brannigan::Validations->max_consec('a!$1234', 4), 'max_consec succeeds when a numeric sequence is exactly than maximum');
ok(!Brannigan::Validations->max_consec('a!$bcde', 3), 'max_consec succeeds when a string sequence is more than maximum');
ok(!Brannigan::Validations->max_consec('a!$1234', 3), 'max_consec succeeds when a numeric sequence is more than maximum');

# max_reps
ok(Brannigan::Validations->max_reps('a!$bbbb', 5), 'max_reps succeeds when a string sequence is less than maximum');
ok(Brannigan::Validations->max_reps('a!$1111', 5), 'max_reps succeeds when a numeric sequence is less than maximum');
ok(Brannigan::Validations->max_reps('a!$bbbb', 4), 'max_reps succeeds when a string sequence is exactly than maximum');
ok(Brannigan::Validations->max_reps('a!$1111', 4), 'max_reps succeeds when a numeric sequence is exactly than maximum');
ok(!Brannigan::Validations->max_reps('a!$bbbb', 3), 'max_reps succeeds when a string sequence is more than maximum');
ok(!Brannigan::Validations->max_reps('a!$1111', 3), 'max_reps succeeds when a numeric sequence is more than maximum');

# max_dict
# not tested yet

done_testing();
