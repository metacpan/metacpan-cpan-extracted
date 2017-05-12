use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exit;
use App::LLEvalBot::CLI;

subtest parse_options => sub {

    subtest 'normal' => sub {
        my ($opt, $argv) = App::LLEvalBot::CLI->parse_options(qw/--host irc.example.com --channels=a hoge/);

        is_deeply $opt, {
            join_channels => [qw/a/],
            host          => 'irc.example.com',
            nickname      => 'lleval_bot',
        };
        is_deeply $argv, [qw/hoge/];
    };

    subtest 'multi channel' => sub {
        my ($opt, $argv) = App::LLEvalBot::CLI->parse_options(qw/--host irc.example.com --channels=a,b --channels=c --nickname=fff hoge/);

        is_deeply $opt, {
            join_channels => [qw/a b c/],
            host          => 'irc.example.com',
            nickname      => 'fff',
        };
        is_deeply $argv, [qw/hoge/];
    };

    subtest 'invalid option' => sub {
        is exit_code { App::LLEvalBot::CLI->parse_options('') }, 2;
    };
};

done_testing;
