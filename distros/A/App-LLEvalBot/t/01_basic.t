use strict;
use warnings;
use utf8;
use Test::More;
use App::LLEvalBot;

my $bot = App::LLEvalBot->new(
    config => {
        nickname => 'lleval_bot',
    },
);

subtest 'normal print' => sub {
    my $result = $bot->call_eval('lleval_bot: print 3;');
    delete $result->{$_} for qw/time syscalls/;
    is_deeply $result, {
        lang   => 'pl',
        status => 0,
        stderr => '',
        stdout => '3',
    };
};

subtest 'print the return value' => sub {
    my $result = $bot->call_eval('lleval_bot: 4');
    delete $result->{$_} for qw/time syscalls/;
    is_deeply $result, {
        lang   => 'pl',
        status => 0,
        stderr => '',
        stdout => '4',
    };
};

subtest 'print the return value' => sub {
    my $result = $bot->call_eval('lleval_bot: rb puts 5');
    delete $result->{$_} for qw/time syscalls/;
    is_deeply $result, {
        lang   => 'rb',
        status => 0,
        stderr => '',
        stdout => "5\n",
    };
};

done_testing;
