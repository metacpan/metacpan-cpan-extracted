#/usr/bin/perl
use v5.10;
use Moose;

use lib 't/lib';
use Bot::Backbone::TestEventLoop;
use Test::More tests => 29;

use_ok('Bot::Backbone::Message');
use_ok('Bot::Backbone::Identity');

{
    package TestBot;
    use Bot::Backbone;

    service test_chat => (
        service => 'TestChat',
    );
}

my $bot = TestBot->new( event_loop => 'Bot::Backbone::TestEventLoop' );
$bot->run;

my $message = Bot::Backbone::Message->new(
    chat  => $bot->services->{test_chat},
    from  => Bot::Backbone::Identity->new(
        username => 'from_username',
        nickname => 'From Username',
    ),
    to    => Bot::Backbone::Identity->new(
        username => 'to_username',
        nickname => 'To Username',
    ),
    group => undef,
    text  => 'This is a test.',
);

# Test Flags

{
    ok(!$message->has_flag('foo'), 'no flag foo');

    $message->add_flag('foo');
    ok($message->has_flag('foo'), 'has flag foo');

    $message->remove_flag('foo');
    ok(!$message->has_flag('foo'), 'no flag foo again');

    ok(!$message->has_flag('bar'), 'no flag bar');
    ok(!$message->has_flag('baz'), 'no flag baz');
    ok(!$message->has_flags(qw( bar baz )), 'no flags bar,baz');
    ok(!$message->has_flags(qw( bar qux )), 'no flags bar,qux');

    $message->add_flags(qw( bar baz ));
    ok($message->has_flag('bar'), 'has flag bar');
    ok($message->has_flag('baz'), 'has flag baz');
    ok($message->has_flags(qw( bar baz )), 'has flags bar,baz');
    ok(!$message->has_flags(qw( bar qux )), 'no flags bar,qux');

}

sub args_text     { [ map { $_->text     } $message->all_args ] }
sub args_original { [ map { $_->original } $message->all_args ] }

# Test Args - basic

{
    is_deeply(args_original(),
              [ 'This ', 'is ', 'a ', 'test.' ], 
              'basic args original');

    is_deeply(args_text(),
              [ 'This', 'is', 'a', 'test.' ],
              'basic args text');
}

# Test Args - with quotes and space

{
    delete $message->{args};
    $message->text(q|  This "is a" test. This is a (really thorough) te[st], 
        don't you think? I just {gotta} [ see if ] it 'can' handle this. |);

    is_deeply(args_original(),
              [ '  This ', '"is a"', ' test. ', 'This ', 'is ', 'a ',
                '(really thorough)', " te[st], \n        ", "don't ", 'you ', 
                'think? ', 'I ', 'just ', '{gotta}', ' [ see if ]', ' it ', 
                "'can'", ' handle ', 'this. ' ],
              'complex args original');

    is_deeply(args_text(),
              [ 'This', 'is a', 'test.', 'This', 'is', 'a', 'really thorough',
                'te[st],', "don't", 'you', 'think?', 'I', 'just', 'gotta',
                ' see if ', 'it', "can", 'handle', 'this.' ],
              'complex args text');
}


# Test Matching

{
    delete $message->{args};
    $message->text(q[!robot make me a sandwich]);

    ok(!$message->match_next(q[!robo]), '!robo is not a match');
    is_deeply(args_text(), [ qw( !robot make me a sandwich ) ], 'args unchanged');
    is($message->text, q[!robot make me a sandwich], 'message unchanged');

    ok($message->match_next(q[!robot]), '!robot is a match');
    is_deeply(args_text(), [ qw( make me a sandwich ) ], 'args loses !robot');
    is($message->text, q[make me a sandwich], 'message loses !robot');

    ok(!$message->match_next_original(q[machen]), 'machen is not a match');
    is_deeply(args_text(), [ qw( make me a sandwich ) ], 'args unchanged');
    is($message->text, q[make me a sandwich], 'message unchanged');

    ok($message->match_next_original(qr/[aekms ]+/), 'regex matches');
    is_deeply(args_text(), [ qw( ndwich ) ], 'args loses make me a sa');
    is($message->text, q[ndwich], 'text loses make me a sa');
}
