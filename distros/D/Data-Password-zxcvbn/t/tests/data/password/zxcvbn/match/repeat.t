#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::zxcvbn qw(cmp_match generate_combinations);
use Data::Password::zxcvbn::Match::Repeat;

sub cmp_r_match {
    my ($i,$j,$token,$base) = @_;
    cmp_match(
        $i,$j,'Repeat',
        token => $token,
        base_token => $base,
    );
}

sub test_making {
    my ($password, $expected, $message) = @_;

    my $matches = Data::Password::zxcvbn::Match::Repeat->make(
        $password,
    );
    cmp_deeply(
        $matches,
        $expected,
        $message,
    ) or explain $matches;
}

sub test_recursing {
    my ($base_token, $repeat_count, $opts, $base_guesses, $base_matches, $message) = @_;
    my $password = $base_token x $repeat_count;

    my $matches = Data::Password::zxcvbn::Match::Repeat->make(
        $password,
        $opts,
    );

    cmp_deeply(
        $matches,
        [ cmp_match(
            0,length($password)-1,'Repeat',
            token => $password,
            base_token => $base_token,
            repeat_count => $repeat_count,
            base_guesses => $base_guesses,
            base_matches => $base_matches,
            guesses => $base_guesses * $repeat_count,
        ) ],
        $message,
    ) or explain $matches;
}

subtest 'scoring' => sub {
    my $match = Data::Password::zxcvbn::Match::Repeat->new({
        token => 'aaa',
        base_token => 'a',
        repeat_count => 3,
        base_guesses => 7,
        i => 0, j => 3,
    });

    is($match->guesses,21,'repeat count just multiplies the base guesses');
};

subtest 'making' => sub {
    test_making('',[],'empty string no match');
    test_making('#',[],'one char no match');

    for my $case (generate_combinations('&&&&&',[qw(@ y4@)],[qw(u u%7)])) {
        my ($password,$i,$j) = @{$case};
        test_making(
            $password,
            [cmp_r_match($i,$j,'&&&&&','&')],
            "matches embedded repeat patterns ($password)",
        );
    }

    for my $length (3..12) {
        for my $chr (qw(a Z 4 &)) {
            my $password = $chr x $length;
            test_making(
                $password,
                [cmp_r_match(0,$length-1,$password,$chr)],
                "matches $length repeats of $chr",
            );
        }
    }

    test_making(
        'BBB1111aaaaa@@@@@@',
        [
            cmp_r_match(0,2,'BBB','B'),
            cmp_r_match(3,6,'1111','1'),
            cmp_r_match(7,11,'aaaaa','a'),
            cmp_r_match(12,17,'@@@@@@','@'),
        ],
        'matches multiple adjacent repeats',
    );
    test_making(
        '2818BBBbzsdf1111@*&@!aaaaaEUDA@@@@@@1729',
        [
            cmp_r_match(4,6,'BBB','B'),
            cmp_r_match(12,15,'1111','1'),
            cmp_r_match(21,25,'aaaaa','a'),
            cmp_r_match(30,35,'@@@@@@','@'),
        ],
        'matches multiple non-adjacent repeats',
    );

    test_making(
        'abab',
        [ cmp_r_match(0,3,'abab','ab') ],
        'matches multi-char repeats',
    );
    test_making(
        'aabaab',
        [ cmp_r_match(0,5,'aabaab','aab') ],
        'matches aab instead of aa',
    );
    test_making(
        'abababab',
        [ cmp_r_match(0,7,'abababab','ab') ],
        'identifies ab as repeat string, even though abab is also repeated',
    );
};

subtest 'making, recursing to other matchers' => sub {
    test_recursing(
        'simple',3,{ ranked_dictionaries => { d1 => { simple => 5 } } },
        6, [ cmp_match(0,5,'Dictionary',token=>'simple') ],
        'should recurse to other matchers',
    );

    test_recursing(
        'a',2,{},
        12, [ cmp_match(0,0,'BruteForce',token=>'a') ],
        'brute force',
    );

    test_recursing(
        'batterystaple',3,{},
        28391350, [
            cmp_match(0,6,'Dictionary',token=>'battery'),
            cmp_match(7,12,'Dictionary',token=>'staple'),
        ],
        'dictionary',
    );
};

done_testing;

