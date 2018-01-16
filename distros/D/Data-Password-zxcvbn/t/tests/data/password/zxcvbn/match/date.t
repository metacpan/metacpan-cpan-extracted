#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::zxcvbn qw(cmp_match generate_combinations);
use Data::Password::zxcvbn::Match::Date;

sub cmp_d_match {
    my ($i,$j,$year,$separator) = @_;
    cmp_match(
        $i,$j,'Date',
        year => $year,
        separator => $separator,
    );
}

sub test_scoring {
    my ($token, $year, $separator, $guesses, $message) = @_;

    my $match = Data::Password::zxcvbn::Match::Date->new({
        token => $token,
        year => $year,
        separator => $separator,
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

    my $matches = Data::Password::zxcvbn::Match::Date->make($password);
    cmp_deeply(
        $matches,
        $expected,
        $message,
    ) or explain $matches;
}

subtest 'scoring' => sub {
    test_scoring(
        '1123', 1923, '' => 365*(2017-1923),
        'guesses for early year is 365 * distance from reference_year=2017',
    );

    test_scoring(
        '1/1/2010', 2010, '/' => 365*20*4,
        'min_year_space=20 for recent years, plus separator'
    );
};

subtest 'making' => sub {
    for my $sep ('',' ',qw(- / \\ _ .)) {
        test_making(
            "13${sep}2${sep}1921",
            [ cmp_d_match(0,6+2*length($sep),1921,$sep) ],
            "matches dates that use '$sep' as separator",
        );
    }

    for my $order (qw(mdy dmy ymd ydm)) {
        my $password = $order;
        $password =~ s{y}{88}; $password =~ s{d}{6}; $password =~ s{m}{7};
        test_making(
            $password,
            [ cmp_d_match(0,3,1988,'') ],
            "matches dates in $order format ($password)",
        );
    }

    test_making(
        '111504',
        [ cmp_d_match(0,5,2004,'') ],
        'matches the date with year closest to REFERENCE_YEAR when ambiguous',
    );

    for my $case (
        [1, 1, 1999],
        [11, 8, 2000],
        [9, 12, 2005],
        [22, 11, 1551],
    ) {
        my ($day, $month, $year) = @{$case};

        for my $sep ('',' ',qw(- / \\ _ .)) {
            my $password = join $sep,$year,$month,$day;
            test_making(
                $password,
                [ cmp_d_match(0,length($password)-1,$year,$sep) ],
                "matches $password as $year",
            );
        }
    }

    test_making(
        '02/02/02',
        [ cmp_d_match(0,7,2002,'/') ],
        'matches zero-padded dates',
    );
};

done_testing;
