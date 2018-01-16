use strict;
use warnings;
use Test::Most;
use Data::Password::zxcvbn::Combinatorics qw(enumerate_substitution_maps);

subtest 'enumerate_substitution_maps' => sub {
    my @cases = (
        [ {'a' => ['@']}  =>  [{'@' => 'a'}] ],

        [ {'a' => ['@', '4']}  =>  [{'@' => 'a'}, {'4' => 'a'}] ],

        [ {'a' => ['@', '4'], 'c' => ['(']}  =>
              [{'(' => 'c', '@' => 'a'}, {'(' => 'c', '4' => 'a'}] ],

        [ {'a' => ['@', '4'], 'c' => ['(', '@']}  =>  [
            {'(' => 'c', '@' => 'a'},
            {'(' => 'c', '4' => 'a'},
            {'@' => 'a'},
            {'@' => 'c'},
            {'4' => 'a', '@' => 'c'}
        ] ],
    );
    for my $case (@cases) {
        my ($table,$expected) = @{$case};
        my $result = enumerate_substitution_maps($table);
        cmp_deeply(
            $result,
            bag(@{$expected}),
            'should produce the expected value',
        ) or explain $result;
    }
};

done_testing;
