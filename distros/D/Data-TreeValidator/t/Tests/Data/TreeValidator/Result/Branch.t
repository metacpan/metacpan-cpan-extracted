use strict;
use warnings;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

use aliased 'Data::TreeValidator::Result::Branch' => 'Result';
use aliased 'Data::TreeValidator::Result::Leaf' => 'LeafResult';

test 'public api' => sub {
    my $result = Result->new(input => {});
    can_ok($result, $_)
        for qw(
            results result_names result_count result
            valid
            clean
        );
};

test 'fetch results' => sub {
    my $leaf_result = LeafResult->new( input => 'leaf' );
    my $result = Result->new(
        results => {
            shiney => $leaf_result
        },
        input => { shiney => 'leaf' }
    );

    is($result->result_count => 1, 'has 1 result');
    is_deeply([ $result->result_names ], [qw( shiney )],
        'has result names');
    is_deeply([ $result->results ], [ $leaf_result ],
        'has result array');
    is($result->result('shiney') => $leaf_result,
        'can fetch result by name');
};

test 'validity' => sub {
    my $valid_result = LeafResult->new( clean => 'Clean', input => 'leaf' );
    my $invalid_result = LeafResult->new( input => 'leaf' );

    my $valid_branch = Result->new(
        results => { leaf => $valid_result },
        input => { }
    );

    my $invalid_branch = Result->new(
        results => { leaf => $invalid_result },
        input => { }
    );

    my $mixed_branch = Result->new(
        results => { leaf1 => $invalid_result, leaf2 => $valid_result },
        input => { }
    );

    ok($valid_branch->valid,
        'a branch is valid if all children are valid');
    ok(!$invalid_branch->valid,
        'a branch is not valid if children are not valid');
    ok(!$mixed_branch->valid,
        'a branch is not valid if children are not valid');
};

test 'clean data' => sub {
    my $clean_data = 'Clean';
    my $valid_result = LeafResult->new( clean => $clean_data, input => 'leaf' );
    my $invalid_result = LeafResult->new( input => 'leaf' );

    my $valid_branch = Result->new(
        results => { leaf => $valid_result },
        input => { }
    );

    my $mixed_branch = Result->new(
        results => { leaf1 => $invalid_result, leaf2 => $valid_result },
        input => { }
    );

    is_deeply($valid_branch->clean, { leaf => $clean_data },
        'branch has clean data');
    is_deeply($mixed_branch->clean, {
        leaf2 => $clean_data 
    },
        'branch result only has clean data');
};

run_me;
done_testing;
