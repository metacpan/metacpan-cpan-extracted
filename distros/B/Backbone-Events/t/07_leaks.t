use strict;
use warnings;
use FindBin::libs;
use Test::Backbone::Events::Utils;
use Test::LeakTrace qw(no_leaks_ok);
use Test::More;

my $handler = test_handler();

no_leaks_ok {
    my $cb = sub {};
    $handler->once('event', $cb);
    $handler->trigger('event');
} 'no leaks triggering once event';

no_leaks_ok {
    my $cb = sub {};
    $handler->once('event', $cb);
    $handler->off('event',  $cb);
} 'no leaks turning off once event';

no_leaks_ok {
    my $cb       = sub {};
    my $listener = test_handler();
    $listener->listen_to_once($handler, 'event', $cb);
    $handler->trigger('event');
} 'no leaks triggering listen_to_once event';

no_leaks_ok {
    my $cb       = sub {};
    my $listener = test_handler();
    $listener->listen_to_once($handler, 'event', $cb);
    $listener->stop_listening;
} 'no leaks turning off listen_to_once event';

done_testing;
