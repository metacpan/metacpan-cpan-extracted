#!/usr/bin/perl
use v5.10;
use Moose;

use lib 't/lib';
use Bot::Backbone::TestEventLoop;
use Test::More tests => 21;

{
    package TestBot::Service::Foo;
    use Bot::Backbone::Service;

    with 'Bot::Backbone::Service::Role::Service';

    use Test::More;

    service_dispatcher as {
        run_this { 
            isa_ok($_[0], 'TestBot::Service::Foo'); 
            is($_[1]->text, 'blah blee bloo', 'dispatched to service'); 
            1 
        };
    };

    sub initialize { 
        my $self = shift;
        pass('initialized');
    }

    sub send_message { die }
    sub send_reply   { die }
}

{
    package TestBot::Service::Bar;
    use Bot::Backbone::Service;

    with 'Bot::Backbone::Service::Role::Service';

    use Test::More;

    has counter => (
        is          => 'rw',
        isa         => 'Int',
        required    => 1,
        default     => 0,
        traits      => [ 'Counter' ],
        handles     => { 'inc' => 'inc' },
    );

    service_dispatcher as {
        command '!barfoo' => run_this_method 'some_method';
        command '!barbar' => respond_by_method 'some_method';
    };

    sub initialize { }

    sub some_method {
        isa_ok($_[0], 'TestBot::Service::Bar');
        is($_[1]->text, '', 'dispatched to service method');

        fail('ran too many times') if $_[0]->inc > 2;

        'barbar';
    }

    sub send_message { die }
    sub send_reply {
        my ($self, $message, $options) = @_;
        is($options->{text}, 'barbar', 'got barbar');
    }
}

{
    package TestBot;
    use Bot::Backbone;

    use Test::More;

    has some_method_counter => (
        is          => 'rw',
        isa         => 'Int',
        required    => 1,
        default     => 0,
        traits      => [ 'Counter' ],
        handles     => { 'some_method_counter_inc' => 'inc' },
    );

    service chat => (
        service    => 'TestChat',
        dispatcher => 'test',
    );

    service foo => (
        service => '.Foo',
    );

    service bar => (
        service => '.Bar',
    );

    service baz => (
        service  => '.Bar',
        commands => {
            '!bazfoo' => '!barfoo',
            '!bazbar' => '!barbar',
        },
    );

    dispatcher test => as {
        command '!foo' => run_this { 
            #diag explain \@_;
            isa_ok($_[0], 'TestBot');
            is($_[1]->text, '', '!foo #1 runs'); 
            1
        };
        command '!foo' => run_this { fail('!foo #2 never runs'); 1 };

        command '!bar' => run_this { is($_[1]->text, 'blah blah', '!bar #1 runs'); 0 };
        command '!bar' => run_this { is($_[1]->text, 'blah blah', '!bar #2 runs'); 1 };
        command '!bar' => run_this { fail('!bar #3 never runs'); 1 };

        command '!baz' => redispatch_to 'foo';

        command '!qux'  => run_this_method 'some_method';
        command '!quux' => respond_by_method 'some_method';

        redispatch_to 'bar';
        redispatch_to 'baz';
    };

    sub some_method {
        isa_ok($_[0], 'TestBot');
        is($_[1]->text, '', 'dispatched to service method');

        fail('ran too many times') if $_[0]->some_method_counter_inc > 2;
    }
}

my $bot = TestBot->new( event_loop => 'Bot::Backbone::TestEventLoop' );
$bot->run;

my $chat = $bot->get_service('chat');
$chat->dispatch( text => '!foo' );
$chat->dispatch( text => '!bar blah blah' );
$chat->dispatch( text => '!baz blah blee bloo' );
$chat->dispatch( text => '!qux' );
$chat->dispatch( text => '!quux' );
$chat->dispatch( text => '!barfoo' );
$chat->dispatch( text => '!barbar' );
$chat->dispatch( text => '!bazfoo' );
$chat->dispatch( text => '!bazbar' );
