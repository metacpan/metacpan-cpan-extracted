use strict;
use Test::More;

use Data::Verifier;

# A successful verification
{
    my $verifier = Data::Verifier->new(
        profile => {
            name    => {
                required => 1
            }
        }
    );

    my $results = $verifier->verify({ name => 'foo' });

    ok($results->success, 'success');

	# Counts
    cmp_ok($results->valid_count, '==', 1, '1 valid');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');

	# Predicates
    ok($results->is_valid('name'), 'name is valid');
	ok(!$results->is_invalid('name'), 'name is not invalid');
	ok(!$results->is_missing('name'), 'name is not missing');
	ok(!$results->is_wrong('name'), 'name is not wrong');
	ok($results->has_field('name'), 'has_field name');

	# Values
    cmp_ok($results->get_value('name'), 'eq', 'foo', 'get_value');
    cmp_ok($results->get_original_value('name'), 'eq', 'foo', 'get_original_value');

	# Arbitrary field
	ok(!$results->is_valid('name2'), 'name2 is NOT valid (unknown field)');
	ok(!$results->is_invalid('name2'), 'name2 is NOT invalid (unknown field)');
	ok(!$results->is_missing('name2'), 'name2 is NOT missing (unknown field)');
	ok(!$results->is_wrong('name2'), 'name2 is NOT wrong (unknown field)');
	ok(!$results->has_field('name2'), 'does not have name2 (unknown field)');
}

# Missing field
{
    my $verifier = Data::Verifier->new(
        profile => {
            name    => {
                required => 1,
            }
        }
    );

    my $results = $verifier->verify({ bar => 'foo' });

    ok(!$results->success, 'failure');

	# Counts
    cmp_ok($results->valid_count, '==', 0, '0 valid');
    cmp_ok($results->invalid_count, '==', 0, '0 invalid');
    cmp_ok($results->missing_count, '==', 1, '1 missing');

	# Predicates
    ok(!$results->is_valid('name'), 'name is not valid');
    ok(!$results->is_invalid('name'), 'name is invalid');
    ok($results->is_missing('name'), 'name is missing');
	ok($results->is_wrong('name'), 'name is wrong');

	# Values
    ok(!defined($results->get_value('name')), 'name has no value');
}

# Invalid field
{
    my $verifier = Data::Verifier->new(
        profile => {
            age     => {
                required => 1,
                type => 'Int'
            }
        }
    );

	my $results = $verifier->verify({ age => 'twenty' });
	
	ok(!$results->success, 'failure');

	# Counts
    cmp_ok($results->valid_count, '==', 0, '0 valid');
    cmp_ok($results->invalid_count, '==', 1, '1 invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');

	# Predicates
    ok(!$results->is_valid('age'), 'name is not valid');
	ok($results->is_invalid('age'), 'age is invalid');
	ok(!$results->is_missing('age'), 'age is not missing');
	ok($results->is_wrong('age'), 'age is wrong');

	# Values
    ok(!defined($results->get_value('age')), 'get_value got undef');
    cmp_ok($results->get_original_value('age'), 'eq', 'twenty', 'get_original_value');
}


{
    my $verifier = Data::Verifier->new(
        profile => {
            name    => {
                required => 1
            },
            age     => {
                required => 1,
                type => 'Int'
            }
        }
    );

    my $results = $verifier->verify({ name => 'foo', age => 0 });

    ok($results->success, 'success');

	# Counts
    cmp_ok($results->valid_count, '==', 2, '2 valid');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');

	# Predicates
    ok($results->is_valid('name'), 'name is valid');
	ok(!$results->is_invalid('age'), 'age is not invalid');
    ok($results->is_valid('age'), 'age is valid');

	# Values
    cmp_ok($results->get_value('name'), 'eq', 'foo', 'get_value');
    my %valids = $results->valid_values;
    is_deeply(\%valids, { name => 'foo', age => 0 }, 'valid_values');
}


done_testing;