#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::zxcvbn qw(cmp_match);
use Data::Password::zxcvbn::Match::UserInput;
use Data::Password::zxcvbn::MatchList;

sub cmp_ui_match {
    my ($i,$j,$word,$dict,%etc) = @_;
    cmp_match(
        $i,$j,'UserInput',
        token => $word,
        dictionary_name => $dict,
        rank => 1,
        %etc
    );
}

sub test_making_and_scoring {
    my ($password, $user_input, $expected_matches, $expected_guesses, $message) = @_;

    subtest $message => sub {
        my $matches = Data::Password::zxcvbn::Match::UserInput->make(
            $password,
            { user_input => $user_input },
        );

        cmp_deeply(
            $matches,
            $expected_matches,
            'the matches should be as expected',
        ) or explain $matches;

        my $result = Data::Password::zxcvbn::MatchList->new({
            password => $password,
            matches => $matches,
        })->most_guessable_match_list(1);

        cmp_deeply(
            $result->guesses,
            $expected_guesses,
            'it should be very guessable',
        ) or explain $result;
    };
}

subtest 'making' => sub {
    test_making_and_scoring(
        'myname', { name => 'myname' },
        [ cmp_ui_match(0,5,'myname','name') ],
        1,
        'simple match',
    );

    test_making_and_scoring(
        'myName', { name => 'Myname' },
        [ cmp_ui_match(0,5,'myName','name') ],
        6,
        'simple match, capitalised input & case-insensitive matching',
    );

    test_making_and_scoring(
        'myname', { full_name => 'myname mysurname' },
        [ cmp_ui_match(0,5,'myname','full_name') ],
        1,
        'simple word breaking',
    );

    test_making_and_scoring(
        'Some1234', { company => 'some-magic1234' },
        [
            cmp_ui_match(0,3,'Some','company'),
            cmp_ui_match(4,7,'1234','company'),
        ],
        5000, # the password is not just a substring of the input
        'more word breaking',
    );

    test_making_and_scoring(
        'some1234', { company => 'Some-Magic1234' },
        [
            cmp_ui_match(0,3,'some','company'),
            cmp_ui_match(4,7,'1234','company'),
        ],
        5000,
        'more word breaking, capitalised input & case-insensitive matching',
    );

    test_making_and_scoring(
        'dave99', { name => 'Mr Dave99 Smith' },
        [
            cmp_ui_match(0,3,'dave','name'),
            cmp_ui_match(0,5,'dave99','name'),
            cmp_ui_match(4,5,'99','name'),
        ],
        1,
        'alnum sequences should match, even when each al or num subsequence is short',
    );

    test_making_and_scoring(
        'Mr Dave99 Smith', { name => 'Mr Dave99 Smith' },
        [
            cmp_ui_match(0,1,'Mr','name'),
            cmp_ui_match(0,14,'Mr Dave99 Smith','name'),
            cmp_ui_match(2,2,' ','name'),
            cmp_ui_match(3,6,'Dave','name'),
            cmp_ui_match(3,8,'Dave99','name'),
            cmp_ui_match(7,8,'99','name'),
            cmp_ui_match(9,9,' ','name'),
            cmp_ui_match(10,14,'Smith','name'),
        ],
        231, # I'm not sure why matching a rank-1 dictionary entry
             # produces such a high guesses estimate
        'the whole input should always be an obvious guess',
    );

    test_making_and_scoring(
        'dave99', { name => 'dave99foo' },
        [
            cmp_ui_match(0,3,'dave','name'),
            cmp_ui_match(4,5,'99','name'),
        ],
        5000, # the password cracker has to split & re-join the sub-sequences
        'alnum sequences should match, even when the input contains longer sequence',
    );

    test_making_and_scoring(
        'u1t1o1', { name => 'u1t1o1' },
        [
            cmp_ui_match(0,0,'u','name'),
            cmp_ui_match(0,5,'u1t1o1','name'),
            cmp_ui_match(1,1,'1','name'),
            cmp_ui_match(2,2,'t','name'),
            cmp_ui_match(3,3,'1','name'),
            cmp_ui_match(4,4,'o','name'),
            cmp_ui_match(5,5,'1','name'),
        ],
        1,
        'extreme example of short sub-sequences',
    );
};

done_testing;
