use strict;
use warnings;
use FindBin::libs;
use Test::Fatal qw(dies_ok);
use Test::More;
use Test::Backbone::Events::Utils;

{
    my $handler  = test_handler();
    my $listener = test_handler();

    my %triggers;
    $listener->listen_to($handler, 'all', sub { $triggers{listener}++ });
    $handler->on('all', sub { $triggers{other}++ });

    $handler->trigger('event');
    is $triggers{listener}, 1, 'triggered event for callback from listen_to';
    is $triggers{other}, 1, 'triggered event for callback from on';

    %triggers = ();
    $listener->stop_listening;
    $handler->trigger('event');
    is $triggers{listener}, undef, 'did not trigger event for listen_to callback after stop_listening';
    is $triggers{other}, 1, 'triggered event for callback from on after unrelated listener stopped listening';
}

{
    my $handler   = test_handler();
    my $listener1 = test_handler();
    my $listener2 = test_handler();

    my $count;
    my $cb = sub { $count++ };
    $listener1->listen_to($handler, 'event', $cb);
    $listener2->listen_to($handler, 'event', $cb);

    $handler->trigger('event');
    is $count, 2, 'callback triggered twice when registered by two listeners';

    $count = 0;
    $listener1->stop_listening;
    $handler->trigger('event');
    is $count, 1, 'callback triggered once once listener with shared callback is removed';
}

{
    my $listener = test_handler();
    my $handler1 = test_handler();
    my $handler2 = test_handler();

    my $count = 0;
    my $cb = sub { $count++ };

    $listener->listen_to($handler1, 'all', $cb);
    $listener->listen_to($handler2, 'all', $cb);
    $_->trigger('event') for $handler1, $handler2;
    is $count, 2, 'callbacks triggered twice when listening to two objects';

    $count = 0;
    $listener->stop_listening($handler2);
    $_->trigger('event') for $handler1, $handler2;
    is $count, 1, 'callbacks triggered once after listening stopped for one object';
}

{
    my $listener = test_handler();
    dies_ok { $listener->listen_to(1, 'event', sub {}) };
    dies_ok { $listener->listen_to({}, 'event', sub {}) };

    my $obj = bless {}, __PACKAGE__;
    dies_ok { $listener->listen_to($obj, 'event', sub {}) };
}

done_testing;
