use strict;
use warnings;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

use aliased 'Data::TreeValidator::Leaf';
use Data::TreeValidator::Constraints qw( required );
use Data::TreeValidator::Util qw( fail_constraint );

test 'leaf public api' => sub {
    my $leaf = Leaf->new;
    can_ok($leaf, $_)
        for qw(
            constraints add_constraint
            transformations add_transformation
            process
        );
};

test 'leaf processing (simple)' => sub {
    my $leaf = Leaf->new;
    my $input = 'Hello!';
    my $result = $leaf->process('Hello!');

    ok(defined $result);
    ok($result->valid, 'simple leaf is valid after processing');
    is($result->clean => $input,
        'simple leaf result has clean data');
    is($result->clean => $input,
        'simple leaf has input');

    $result = $leaf->process(undef);
    ok($result->valid, 'leaf can take "undef" input');
    is($result->input => undef, 'input is undef');
    is($result->clean => undef, 'clean data is undef');
};

test 'leaf with failing constraints' => sub {
    my $always_fail = sub { fail_constraint 'Invalid' };
    my $leaf = Leaf->new;
    $leaf->add_constraint($always_fail);

    my $input = 'Hello!';
    my $result = $leaf->process($input);

    ok(defined $result, 'leaf with constraints gives a result object');
    ok(!$result->valid,
        'leaf that doesnt pass constraints does not give a valid result');
    is($result->errors => 1, 'result object has errors');
    is(($result->errors)[0] => 'Invalid', 'result object has error message');
    is_deeply($result->input => $input, 'result has input');
    ok(!$result->has_clean_data, 'result has no clean data');
};

test 'leaf with passing constraints' => sub {
    my $always_pass = sub { };
    my $leaf = Leaf->new;
    $leaf->add_constraint($always_pass);

    my $input = 'Hello!';
    my $result = $leaf->process($input);

    ok(defined $result, 'leaf with constraints gives a result object');
    ok($result->valid,
        'leaf that passes constraints gives a valid result');
    is($result->errors => 0, 'result object has no errors');
    is_deeply($result->input => $input, 'result has input');
    ok($result->has_clean_data, 'result has clean data');
    is($result->clean => $input, 'clean data maches input');
};

test 'leaf with an initializer' => sub {
    my $leaf = Leaf->new;
   
    my $initialize = 'Value';
    my $result = $leaf->process(undef, initialize => $initialize);

    ok($result->valid, 'processing with an initializer gives a valid result');
    is($result->clean => $initialize,
        'clean value takes the initializers value');
};

test 'Can process with required/false string' => sub {
    my $leaf = Leaf->new;
    $leaf->add_constraint(required);

    my $result = $leaf->process('0');
    ok($result->valid, 'processing with 0 + required constraint is valid');
};

run_me;
done_testing;
