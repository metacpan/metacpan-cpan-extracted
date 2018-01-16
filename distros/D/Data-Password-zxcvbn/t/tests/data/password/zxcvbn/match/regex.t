#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::zxcvbn qw(cmp_match);
use Data::Password::zxcvbn::Match::Regex;

sub cmp_r_match {
    my ($i,$j,$name) = @_;
    cmp_match(
        $i,$j,'Regex',
        regex_name => $name,
    );
}

sub test_scoring {
    my ($token, $regex_name, $guesses, $message) = @_;

    my $match = Data::Password::zxcvbn::Match::Regex->new({
        token => $token,
        regex_name => $regex_name,
        i => 0, j => 3,
    });

    is(
        $match->guesses,
        $guesses,
        $message,
    );
}

sub test_making {
    my ($password, $all, $expected, $message) = @_;

    my $matches = Data::Password::zxcvbn::Match::Regex->make(
        $password,
        { regexes => $all },
    );
    cmp_deeply(
        $matches,
        $expected,
        $message,
    ) or explain $matches;
}

subtest 'scoring' => sub {
    test_scoring(
        'aizocdk', 'alpha_lower' => 26**7,
        'guesses of 26^7 for 7-char lowercase regex',
    );

    test_scoring(
        'ag7C8', 'alphanumeric' => (2*26+10)**5,
        'guesses of 62^5 for 5-char alphanumeric regex',
    );

    test_scoring(
        '1972', 'recent_year' => 45,
        'guesses of |year - REFERENCE_YEAR=2017| for distant year matches',
    );

    test_scoring(
        '2005', 'recent_year' => 20,
        'guesses of MIN_YEAR_SPACE=20 for a year close to REFERENCE_YEAR',
    );
};

subtest 'making' =>  sub {
    test_making(
        '1922',undef,
        [cmp_r_match(0,3,'recent_year')],
        'matches a year as a recent_year',
    );
    test_making(
        '2017',undef,
        [cmp_r_match(0,3,'recent_year')],
        'matches a year as a recent_year',
    );

    test_making(
        '1922','all',
        bag(
            cmp_r_match(0,3,'recent_year'),
            cmp_r_match(0,3,'digits'),
        ),
        'matches a year as a recent_year, a digit string, and an alphanumeric string',
    );

    test_making(
        'abcde','all',
        bag(
            cmp_r_match(0,4,'alpha_lower'),
            cmp_r_match(0,4,'alpha'),
        ),
        'matches a lowercase string as alpha and alpha_lower',
    );

    test_making(
        'abcde1234ABDCE','all',
        bag(
            cmp_r_match(0,4,'alpha_lower'),
            cmp_r_match(0,4,'alpha'),
            cmp_r_match(5,8,'digits'),
            cmp_r_match(9,13,'alpha_upper'),
            cmp_r_match(9,13,'alpha'),
        ),
        'matches a mixed string all the possible ways',
    );

    test_making(
        '12345+-*&[],,','all',
        [
            cmp_r_match(0,4,'digits'),
            cmp_r_match(5,12,'symbols'),
        ],
        'matches are sorted',
    );
};

done_testing;
