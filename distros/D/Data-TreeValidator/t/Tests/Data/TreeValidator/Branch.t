use strict;
use warnings;
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use lib 't/lib';

use aliased 'Data::TreeValidator::Branch';
use aliased 'Mock::Data::TreeValidator::Leaf' => 'MockLeaf';

test 'branch public api' => sub {
    my $branch = Branch->new;
    can_ok($branch, $_)
        for qw(
            children child_names add_child child
            process
        );
};

test 'empty branch' => sub {
    my $branch = Branch->new;

    my $result = $branch->process( {} );
    ok(defined $result, 'can process with no input');
    ok($result->valid, 'gives a valid result');
    is_deeply($result->clean => {}, 'result has no data');
};

test 'empty branch with input' => sub {
    my $branch = Branch->new;

    my $result = $branch->process( { ignore => 'me' } );
    ok(defined $result, 'can process with extra input');
    ok($result->valid, 'gives a valid result');
    is_deeply($result->clean => {}, 'result has no data');
};

test 'branch with children' => sub {
    my $child = MockLeaf->new;
    my $branch = Branch->new(
        children => {
            child => $child
        }
    );

    my $input = { child => 'Hurrah' };
    my $result = $branch->process($input);
    ok($child->was_processed, 'processes all children');
    is_deeply($result->input => $input,
        'the result object has the given input');
    is($result->result('child')->input => 'Hurrah',
        'the result object has correct result objects for children');
    is($result->result_count => 1,
        'result object only has results for children');
};

test 'branch with an initializer' => sub {
    my $leaf = MockLeaf->new;
    my $branch = Branch->new(
        children => {
            child => $leaf
        }
    );
   
    my $initialize = { child => 'Value' };
    my $result = $branch->process(undef, initialize => $initialize);

    ok($result->valid,
        'processing with an initializer gives a valid result');
    is_deeply($result->clean => $initialize,
        'clean value takes the initializers value');
};

test 'branch with a cross node validator' => sub {
    use Data::TreeValidator::Util qw( fail_constraint );

    my $leaf = MockLeaf->new;
    my $error_message = 'value1 and value2 must be equal';
    my $branch = Branch->new(
        children => {
            value1 => $leaf,
            value2 => $leaf
        },
        cross_validator => sub {
            my $clean = shift;
            fail_constraint($error_message)
                unless $clean->{value1} eq $clean->{value2};
        }
    );

    subtest 'test with valid data' => sub {
        my $input = {    
            value1 => 'hello',
            value2 => 'hello',
        };
        my $result = $branch->process($input);

        ok($result->valid,
            'processing with data that meets cross validator is valid');
        is_deeply($result->clean => $input,
            'clean data matches input');
    };

    subtest 'test with invalid data' => sub {
        my $result = $branch->process({
            value1 => 'hello',
            value2 => 'goodbye',
        });

        ok(!$result->valid,
            'processing with data that does not meet cross validator is '.
            'invalid');
        is($result->errors => 1, 'has one error');
        ok((grep { $_ eq $error_message } $result->errors),
            'has the error from the cross validator');
    };
};

run_me;
done_testing;
