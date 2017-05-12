#!perl

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Bash qw(join_wordbreak_words);
use Test::More;

subtest "basic" => sub {
    is_deeply(
        join_wordbreak_words([qw/cmd --foo = bar -MData :: Dump bob @ example.com > 2/], 9),
        [ [qw/cmd --foo=bar -MData::Dump bob@example.com > 2/], 3 ]
    );
};

subtest "no join at CWORD" => sub {
    # Orig cmd with mark:
    # cmd --^foo=bar
    is_deeply(
        # After parse_cmdline with NO truncate_current_word:
        # words = qw/cmd --foo = bar/
        # cword = 1
        join_wordbreak_words([qw/cmd --foo = bar/], 1),
        [ [qw/cmd --foo =bar/], 1 ],
        'after truncate_current_word = 0'
    );
    is_deeply(
        # After parse_cmdline with truncate_current_word:
        # words = qw/cmd -- = bar/
        # cword = 1
        join_wordbreak_words([qw/cmd -- = bar/], 1),
        [ [qw/cmd -- =bar/], 1 ],
        'after truncate_current_word = 1'
    );
};

DONE_TESTING:
done_testing;
