#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::zxcvbn qw(cmp_match);
use Data::Password::zxcvbn::Match::UserInput;

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

sub test_making {
    my ($password, $user_input, $expected, $message) = @_;

    my $matches = Data::Password::zxcvbn::Match::UserInput->make(
        $password,
        { user_input => $user_input },
    );
    cmp_deeply(
        $matches,
        $expected,
        $message,
    ) or explain $matches;
}

subtest 'making' => sub {
    test_making(
        'myname', { name => 'myname' },
        [ cmp_ui_match(0,5,'myname','name') ],
        'simple match',
    );

    test_making(
        'myName', { name => 'Myname' },
        [ cmp_ui_match(0,5,'myName','name') ],
        'simple match, capitalised input & case-insensitive matching',
    );

    test_making(
        'myname', { full_name => 'myname mysurname' },
        [ cmp_ui_match(0,5,'myname','full_name') ],
        'simple word breaking',
    );

    test_making(
        'Some1234', { company => 'some-magic1234' },
        [
            cmp_ui_match(0,3,'Some','company'),
            cmp_ui_match(4,7,'1234','company'),
        ],
        'more word breaking',
    );

    test_making(
        'some1234', { company => 'Some-Magic1234' },
        [
            cmp_ui_match(0,3,'some','company'),
            cmp_ui_match(4,7,'1234','company'),
        ],
        'more word breaking, capitalised input & case-insensitive matching',
    );
};

done_testing;
