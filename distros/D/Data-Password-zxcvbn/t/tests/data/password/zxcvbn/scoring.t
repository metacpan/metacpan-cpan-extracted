#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::zxcvbn qw(match_for_testing cmp_match cmp_sequence);
use Data::Password::zxcvbn::MatchList;

sub test_scoring {
    my ($input,$expected,$message) = @_;

    my $password = '0123456789';
    my $result = Data::Password::zxcvbn::MatchList->new({
        password => $password,
        matches => $input,
    })->most_guessable_match_list(1);

    cmp_sequence(
        $result,
        $expected,
        $message,
    );
}

subtest 'empty match sequence' => sub {
    test_scoring(
        [],
        [ cmp_match(0,9,'BruteForce') ],
        'returns one bruteforce match',
    );
};

subtest 'match covers prefix of password' => sub {
    my $match = match_for_testing(0,5,1);
    test_scoring(
        [ $match ],
        [ $match, cmp_match(6,9,'BruteForce') ],
        'returns match + bruteforce',
    );
};

subtest 'match covers suffix of password' => sub {
    my $match = match_for_testing(3,9,1);
    test_scoring(
        [$match],
        [ cmp_match(0,2,'BruteForce'), $match ],
        'returns bruteforce + match',
    );
};

subtest 'match covers infix of password' => sub {
    my $match = match_for_testing(1,8,1);
    test_scoring(
        [$match],
        [
            cmp_match(0,0,'BruteForce'),
            $match,
            cmp_match(9,9,'BruteForce'),
        ],
        'returns bruteforce + match + bruteforce',
    );
};

subtest 'given two matches of the same span' => sub {
    my $matches = [ match_for_testing(0,9,1), match_for_testing(0,9,2) ];
    test_scoring(
        $matches,
        [ $matches->[0] ],
        'chooses lower-guesses match',
    );

    $matches = [ match_for_testing(0,9,3), match_for_testing(0,9,2) ];
    test_scoring(
        $matches,
        [ $matches->[1] ],
        'and the order in which matches are given does not matter',
    );
};

subtest 'when m0 covers m1 and m2' => sub {
    my $matches = [
        match_for_testing(0,9,3),
        match_for_testing(0,3,2),
        match_for_testing(4,9,1),
    ];
    test_scoring(
        $matches,
        { guesses => 3, matches => [ $matches->[0] ] },
        'choose [m0] when m0 < m1 * m2 * fact(2)',
    );

    $matches = [
        match_for_testing(0,9,5),
        match_for_testing(0,3,2),
        match_for_testing(4,9,1),
    ];
    test_scoring(
        $matches,
        { guesses => 4, matches => [ $matches->[1], $matches->[2] ] },
        'choose [m1,m2] when m0 > m1 * m2 * fact(2)',
    );
};

done_testing;
