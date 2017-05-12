#!/usr/bin/perl
use v5.10;
use Moose;

use lib 't/lib';

use Test::More tests => 14;
use Bot::Backbone::TestEventLoop;

{
    package TestBot;
    use Bot::Backbone;

    use Test::More;

    service chat => (
        service    => 'TestChat',
        dispatcher => 'test',
    );

    dispatcher test => as {
        command 'one' => run_this { pass('command, run_this'); };
        command 'two' => to_me run_this { pass('command, to_me, run_this'); };
        command 'three' => not_to_me run_this { pass('command, not_to_me, run_this'); };
        command 'four' => spoken run_this { pass('command, spoken, run_this'); };
        command 'five' => shouted run_this { pass('command, shouted, run_this'); };
        command 'six' => whispered run_this { pass('command, whispered, run_this'); };
        command 'seven' => given_parameters {
            parameter 'a' => ( match => qr/\d+/ );
        } run_this { 
            my ($bot, $m) = @_;
            is($m->parameters->{a}, 7, 'command, whispered, run_this, given_parameters');
        };
        also command 'seven' => run_this { pass('also, command, run_this') };
        command 'eight' => run_this_method 'do_eight';
        command 'nine' => respond {
            pass('command, respond');
            return 'nine';
        };
        command 'ten' => respond_by_method 'do_ten';
        not_command run_this { pass('not_command, run_this'); };
    };

    sub do_eight {
        pass('command, run_this_method');
    }

    sub do_ten {
        ok('command, respond_by_method');
        return 'ten';
    }
}

my $bot = TestBot->new( event_loop => 'Bot::Backbone::TestEventLoop' );
$bot->run;

my $chat = $bot->get_service('chat');
$chat->dispatch( text => 'one' );
$chat->dispatch( text => 'two' );
$chat->dispatch( text => 'three' );
$chat->dispatch( text => 'four' );
$chat->dispatch( text => 'five' );
$chat->dispatch( text => 'six' );
$chat->dispatch( text => 'seven' );
$chat->dispatch( text => 'seven 7' );
$chat->dispatch( text => 'eight' );
$chat->dispatch( text => 'nine' );
is($chat->mq_count, 1, 'nine responded');
is($chat->mq->[0]->{text}, 'nine', 'nine replied nine');
$chat->dispatch( text => 'ten' );
is($chat->mq_count, 2, 'ten responded');
is($chat->mq->[1]->{text}, 'ten', 'ten replied ten');
$chat->dispatch( text => 'something else' );
