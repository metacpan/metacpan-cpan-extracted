use strict;
use warnings;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

use lib 't/lib';

use aliased 'Data::TreeValidator::Branch';
use aliased 'Data::TreeValidator::RepeatingBranch';
use aliased 'Mock::Data::TreeValidator::Leaf' => 'MockLeaf';

test 'repeating branch api' => sub {
    my $branch = RepeatingBranch->new;
    isa_ok($branch, Branch);
};

test 'single repetition' => sub {
    my $leaf = MockLeaf->new;
    my $branch = RepeatingBranch->new(
        children => {
            test => $leaf
        }
    );
 
    my $input = 'Gummy bears!';
    my $result = $branch->process([ { test => $input } ]);
    ok(defined $result, 'processing a repeating branch yields a result');
    ok($result->valid, 'result is valid');
    is($leaf->process_count => 1, 'leaf was processed once');
    is_deeply($result->clean, [
        { test => $input }
    ], 'result has correct clean data');
};

test 'multiple repetitions' => sub {
    my $leaf = MockLeaf->new;
    my $branch = RepeatingBranch->new(
        children => {
            test => $leaf
        }
    );

    my $input1 = 'Gummy bears!';
    my $input2 = 'Steeeeve';

    my $result = $branch->process([
        { test => $input1 },
        { test => $input2 }
    ]);
    ok(defined $result, 'processing a repeating branch yields a result');
    ok($result->valid, 'result is valid');
    is($leaf->process_count => 2, 'leaf was processed twice');
    is_deeply($result->clean, [
        { test => $input1 },
        { test => $input2 }
    ], 'result has correct clean data');
};

test 'repeating branch with initializers' => sub {
    my $leaf = MockLeaf->new;
    my $branch = RepeatingBranch->new(
        children => {
            child => $leaf
        }
    );
   
    my $initialize = [
        { child => 'First value' },
        { child => 'Second value' }
    ];
    my $result = $branch->process(undef, initialize => $initialize);

    ok($result->valid,
        'processing with a initialize value gives a valid result');
    is_deeply($result->clean => $initialize,
        'clean value takes the initialize value');
};

run_me;
done_testing;

