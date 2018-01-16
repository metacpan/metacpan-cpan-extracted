#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::zxcvbn qw(cmp_match generate_combinations);
use Data::Password::zxcvbn::Match::Sequence;

sub cmp_s_match {
    my ($i,$j,$token,$asc) = @_;
    cmp_match(
        $i,$j,'Sequence',
        token => $token,
        ascending => bool($asc),
    );
}

sub test_scoring {
    my ($token, $ascending, $guesses, $message) = @_;

    my $match = Data::Password::zxcvbn::Match::Sequence->new({
        token => $token,
        ascending => $ascending,
        i => 0, j => 3,
    });

    is(
        $match->guesses,
        $guesses,
        $message,
    );
}

sub test_making {
    my ($password, $expected, $message) = @_;

    my $matches = Data::Password::zxcvbn::Match::Sequence->make(
        $password,
    );
    cmp_deeply(
        $matches,
        $expected,
        $message,
    ) or explain $matches;
}

subtest 'scoring' => sub {
    test_scoring(
        'ab', 1 => 4 * 2,
        'obvious start * len',
    );

    test_scoring(
        'XYZ', 1 => 26 * 3,
        'base26 * len',
    );

    test_scoring(
        '4567', 1 => 10 * 4,
        'base10 * len',
    );

    test_scoring(
        '7654', 0 => 10 * 4 * 2,
        'base10 * len * descending',
    );

    test_scoring(
        'ZYX', 0 => 4 * 3 * 2,
        'obvious start * len * descending',
    );
};

subtest 'making' => sub {
    test_making('',[],'empty string no match');
    test_making('a',[],'1-char no match');
    test_making('1',[],'1-char no match');

    test_making(
        'abcbabc',
        [
            cmp_s_match(0,2,'abc',1),
            cmp_s_match(2,4,'cba',0),
            cmp_s_match(4,6,'abc',1),
        ],
        'matches overlapping patterns',
    );

    for my $case (generate_combinations('jihg',[qw(! 22)],[qw(! 22)])) {
        my ($password,$i,$j) = @{$case};
        test_making(
            $password,
            [ cmp_s_match($i,$j,'jihg',0) ],
            'matches embedded patterns',
            );
    }

    test_making(
        "\x{0430}\x{0432}\x{0434}",
        [ cmp_s_match(0,2,ignore(),1) ],
        'matches Cyrillic',
    );
};

done_testing;

