use strict;
use warnings;
use Test::Most;
use Data::Password::zxcvbn::TimeEstimate qw(guesses_to_score display_time);

subtest 'guesses_to_score' => sub {
    for my $case (
        [ 1e2, 0 ],
        [ 1e4, 1 ],
        [ 1e7, 2 ],
        [ 1e9, 3 ],
        [ 1e12, 4 ],
    ) {
        my ($guesses,$expected_score) = @{$case};
        is(
            guesses_to_score($guesses),
            $expected_score,
            'should produce the expected value',
        );
    }
};

subtest 'display_time' => sub {
    for my $case (
        [ 5, ['[quant,_1,second]',5] ],
        [ 320, ['[quant,_1,minute]',5] ],
        [ 7300, ['[quant,_1,hour]',2] ],
        [ 276480, ['[quant,_1,day]',3] ],
        [ 11517120, ['[quant,_1,month]',4] ],
        [ 220903200, ['[quant,_1,year]',7] ],
        [ 1e10, ['centuries'] ],
    ) {
        my ($time,$expected_display) = @{$case};
        my $got = display_time($time);
        cmp_deeply(
            $got,
            $expected_display,
            'should produce the expected value',
        ) or explain $got;
    }
};

done_testing;

