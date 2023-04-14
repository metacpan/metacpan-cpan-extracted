#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::zxcvbn qw(cmp_match generate_combinations);
use Data::Password::zxcvbn::Match::Dictionary;

sub _cmp_dict_match {
    my ($i,$j,$word,$dict,$rank,%etc) = @_;
    cmp_match(
        $i,$j,'Dictionary',
        token => $word,
        dictionary_name => $dict,
        rank => $rank,
        %etc
    );
}

sub cmp_simple_match {
    my ($i,$j,$word,$dict,$rank) = @_;
    _cmp_dict_match(
        $i,$j,$word,$dict,$rank,
        reversed => bool(0),
        l33t => bool(0),
    );
}

sub cmp_rev_match {
    my ($i,$j,$word,$dict,$rank) = @_;
    _cmp_dict_match(
        $i,$j,$word,$dict,$rank,
        reversed => bool(1),
        l33t => bool(0),
    );
}

sub cmp_l33t_match {
    my ($i,$j,$word,$dict,$rank,$subs) = @_;
    _cmp_dict_match(
        $i,$j,$word,$dict,$rank,
        reversed => bool(0),
        l33t => bool(1),
        substitutions => $subs,
    );
}

sub test_scoring {
    my ($token, $reversed, $subs, $rank, $guesses, $message) = @_;

    my $match = Data::Password::zxcvbn::Match::Dictionary->new({
        token => $token,
        reversed => $reversed,
        substitutions => $subs,
        rank => $rank,
        i => 0, j => 3,
    });

    cmp_deeply(
        $match->guesses,
        $guesses,
        $message,
    );
}

sub test_making {
    my ($password, $dicts, $l33t_table, $expected, $message) = @_;

    my $matches = Data::Password::zxcvbn::Match::Dictionary->make(
        $password,
        { ranked_dictionaries => $dicts, l33t_table => $l33t_table },
    );
    cmp_deeply(
        $matches,
        $expected,
        $message,
    ) or explain $matches;
}

subtest 'scoring' => sub {
    subtest 'all variations' => sub {
        test_scoring(
            'aaaaa',0,{},32 => 32,
            'base guesses == rank',
        );

        test_scoring(
            'AAAaaa',0,{},32 => 1312,
            'extra guesses are added for capitalization',
        );

        test_scoring(
            'aaa',1,{},32 => 64,
            'guesses are doubled when word is reversed',
        );

        test_scoring(
            'aaa@@@',0,{'@'=>'a'},32 => 1312,
            'extra guesses are added for common l33t substitutions',
        );

        test_scoring(
            'AaA@@@',0,{'@'=>'a'},32 => 3936,
            'extra guesses are added for both capitalization and common l33t substitutions',
        );
    };

    subtest 'uppercase variations' => sub {
        test_scoring(
            '',0,{},1 => 1,
            'empty string',
        );
        test_scoring(
            'a',0,{},1 => 1,
            'lowercase letter',
        );
        test_scoring(
            'A',0,{},1 => 2,
            'uppercase letter',
        );
        test_scoring(
            'abcdef',0,{},1 => 1,
            'lowercase string',
        );
        test_scoring(
            'Abcdef',0,{},1 => 2,
            'initial uppercase letter',
        );
        test_scoring(
            'abcdeF',0,{},1 => 2,
            'final uppercase letter',
        );
        test_scoring(
            'ABCDEF',0,{},1 => 2,
            'all uppercase string',
        );
        test_scoring(
            'aBcdef',0,{},1 => 6,
            'middle uppercase letter',
        );
        test_scoring(
            'aBcDef',0,{},1 => 21,
            'multiple uppercase letters',
        );
        test_scoring(
            'ABCDEf',0,{},1 => 6,
            'all uppercase but last',
        );
        test_scoring(
            'aBCDEf',0,{},1 => 21,
            'all uppercase but first & last',
        );
        test_scoring(
            'ABCdef',0,{},1 => 41,
            'half uppercase, half lowercase',
        );
    };

    subtest 'l33t variations' => sub {
        test_scoring(
            '',0,{},1 => 1,
            'empty string',
        );
        test_scoring(
            'a',0,{},1 => 1,
            'single letter',
        );
        test_scoring(
            '4',0,{4=>'a'},1 => 2,
            'single letter, substituted',
        );
        test_scoring(
            '4pple',0,{4=>'a'},1 => 2,
            'word, one substition',
        );
        test_scoring(
            'abcet',0,{},1 => 1,
            'word, no substitions',
        );
        test_scoring(
            '4bcet',0,{4=>'a'},1 => 2,
            'word, one substition',
        );
        test_scoring(
            'a8cet',0,{8=>'b'},1 => 2,
            'word, one substition',
        );
        test_scoring(
            'abce+',0,{'+'=>'t'},1 => 2,
            'word, one substition',
        );
        test_scoring(
            '48cet',0,{4=>'a',8=>'b'},1 => 4,
            'word, two different substitions',
        );
        test_scoring(
            'a4a4aa',0,{4=>'a'},1 => 21,
            'word, two of the same substition',
        );
        test_scoring(
            '4a4a44',0,{4=>'a'},1 => 21,
            'word, all-but-two of the same substition',
        );
        test_scoring(
            'a44att+',0,{4=>'a','+'=>'t'},1 => 30,
            'word, two substitions, two of each',
        );

        test_scoring(
            'Aa44aA',0,{},1 => 10,
            'checking capitalization',
        );

        test_scoring(
            'Aa44aA',0,{4=>'a'},1 => 210,
            'capitalisation should not affect the guesses',
        );
    };
};

subtest 'making' => sub {
    subtest 'simple' => sub {
        my $dicts = {
            'd1' => {
                'motherboard' => 1,
                'mother' => 2,
                'board' => 3,
                'abcd' => 4,
                'cdef' => 5,
            },
            'd2' => {
                'z' => 1,
                '8' => 2,
                '99' => 3,
                '$' => 4,
                'asdf1234&*' => 5,
            },
        };

        test_making(
            'motherboard',$dicts,{},
            [
                cmp_simple_match(0,5,'mother','d1',2),
                cmp_simple_match(0,10,'motherboard','d1',1),
                cmp_simple_match(6,10,'board','d1',3),
            ],
            'words and parts should match',
        );

        test_making(
            'abcdef',$dicts,{},
            [
                cmp_simple_match(0,3,'abcd','d1',4),
                cmp_simple_match(2,5,'cdef','d1',5),
            ],
            'overlapping words should match',
        );

        test_making(
            'BoaRdZ',$dicts,{},
            [
                cmp_simple_match(0,4,'BoaRd','d1',3),
                cmp_simple_match(5,5,'Z','d2',1),
            ],
            'ignore case',
        );

        my $word = 'asdf1234&*';
        for my $combination (generate_combinations(
            $word,
            [qw(q %%)],
            [qw(% qq)]
        )) {
            my ($password, $i, $j) = @{$combination};
            test_making(
                $password, $dicts,{},
                [
                    cmp_simple_match($i,$j,$word,'d2',5),
                ],
                'identifies words surrounded by non-words',
            );
        }

        for my $name (keys %{$dicts}) {
            for my $word (keys %{$dicts->{$name}}) {
                # skip words that contain others
                next if $word eq 'motherboard';

                my $rank = $dicts->{$name}{$word};
                test_making(
                    $word, $dicts,{},
                    [
                        cmp_simple_match(0,length($word)-1,$word,$name,$rank),
                    ],
                    'matches against all words in provided dictionaries',
                );
            }
        }

        test_making(
            'wow',undef,undef,
            [
                cmp_simple_match(0,2,'wow','us_tv_and_film',329),
            ],
            'default dictionaries',
        );
    };

    subtest 'reversed' => sub {
        my $dicts = {
            d1 => {
                123 => 1,
                321 => 2,
                456 => 3,
                654 => 4,
            },
        };

        test_making(
            '0123456789',$dicts,{},
            [
                cmp_simple_match(1,3,'123','d1',1),
                cmp_rev_match(1,3,'321','d1',2),
                cmp_simple_match(4,6,'456','d1',3),
                cmp_rev_match(4,6,'654','d1',4),
            ],
            'matches against reversed words',
        );
    };

    subtest 'l33t' => sub {
        my $table = {
            'a' => ['4', '@'],
            'c' => ['(', '{', '[', '<'],
            'g' => ['6', '9'],
            'o' => ['0'],
        };

        my $dicts = {
            words => {
                aac => 1,
                password => 3,
                paassword => 4,
                asdf0 => 5,
            },
            words2 => { cgo => 1 },
        };

        for my $case ( ['', {}],
                       ['abcdefgo123578!#$&*)]}>', {}],
                       ['a', {}],
                       ['4', {a=>['4']}],
                       ['4@', {a=>['4','@']}],
                       ['4({60', {a=>['4'],c=>['(','{'],g=>['6'],o=>['0']}],
                   ) {
            my ($password, $expected) = @{$case};
            my $got = Data::Password::zxcvbn::Match::Dictionary->_relevant_l33t_subtable($password,$table);
            cmp_deeply(
                $got,
                $expected,
                'reduces l33t table to only the substitutions that a password might be employing',
            );
        }

        test_making(
            '',$dicts,$table,
            [],
            'empty string never matches',
        );
        test_making(
            'password',$dicts,$table,
            [cmp_simple_match(0,7,'password','words',3)],
            'pure dictionary words are not l33t-matched',
        );

        test_making(
            'p4ssword',$dicts,$table,
            [cmp_l33t_match(0,7,'p4ssword','words',3,{4=>'a'})],
            'simple replacement',
        );
        test_making(
            'p4ssw0rd',$dicts,$table,
            [cmp_l33t_match(0,7,'p4ssw0rd','words',3,{4=>'a',0=>'o'})],
            'double replacement',
        );
        test_making(
            'aSdfO{G0asDfO',$dicts,$table,
            [cmp_l33t_match(5,7,'{G0','words2',1,{'{'=>'c',0=>'o'})],
            'substring + case',
        );
        test_making(
            '@a(go{G0',$dicts,$table,
            [
                cmp_l33t_match(0,2,'@a(','words',1,{'@'=>'a','('=>'c'}),
                cmp_l33t_match(2,4,'(go','words2',1,{'('=>'c'}),
                cmp_l33t_match(5,7,'{G0','words2',1,{'{'=>'c',0=>'o'}),
            ],
            'overlapping matches',
        );
        test_making(
            'p4@ssword',$dicts,$table,
            [],
            "doesn't match when multiple l33t substitutions are needed for the same letter",
        );
        test_making(
            '4 1 @',$dicts,$table,
            [],
            "doesn't match single-character l33ted words",
        );
        # known issue: subsets of substitutions aren't tried.  for
        # long inputs, trying every subset of every possible
        # substitution could quickly get large, but there might be a
        # performant way to fix.  (so in this example: {4=>a,
        # '0'=>'o'} is detected as a possible sub, but the subset
        # {4=>'a'} isn't tried, missing the match for asdf0.)
        #
        # TODO: consider partially fixing by trying all subsets of
        # size 1 and maybe 2
        test_making(
            '4sdf0',$dicts,$table,
            [],
            "doesn't match with subsets of possible l33t substitutions",
        );
    };
};

done_testing;
