use strict;
use warnings;
use FindBin::libs;
use Test::Fatal qw(dies_ok);
use Test::More;
use Test::Backbone::Events::Utils;

my $listener = test_handler();
my $handler  = test_handler();
my $other    = test_handler();

my $count = 0;
my $cb    = sub { $count++ };

$listener->listen_to($handler, 'test-event', $cb);
$listener->stop_listening($other);
$handler->trigger('test-event');
is $count, 1, 'triggered callback after listening stopped for other object';

$count = 0;
$listener->stop_listening;
$listener->listen_to($handler, 'test-event', $cb);
$listener->stop_listening($handler);
$handler->trigger('test-event');
is $count, 0, 'no callback after listening stopped for object';

$count = 0;
$listener->stop_listening;
$listener->listen_to($handler, 'test-event', $cb);
$listener->stop_listening(undef, 'different-event');
$handler->trigger('test-event');
is $count, 1, 'triggered callback after listening stopped for different event';

$count = 0;
$listener->stop_listening;
$listener->listen_to($handler, 'test-event', $cb);
$listener->stop_listening(undef, 'test-event');
$handler->trigger('test-event');
is $count, 0, 'no callback after listening stopped for event';

$count = 0;
$listener->stop_listening;
$listener->listen_to($handler, 'test-event', $cb);
$listener->stop_listening(undef, undef, $cb);
$handler->trigger('test-event');
is $count, 0, 'no callback after listening stopped for callback';

$count = 0;
$listener->stop_listening;
$listener->listen_to($handler, 'test-event', $cb);
$listener->stop_listening(undef, undef, sub {});
$handler->trigger('test-event');
is $count, 1, 'triggered callback after listening stopped for other callback';

$count = 0;
$listener->stop_listening;
$listener->listen_to($handler, 'test-event', $cb);
$listener->listen_to($handler, 'test-event', sub { goto &$cb });
$listener->stop_listening(undef, 'test-event');
$handler->trigger('test-event');
is $count, 0, 'no callback after listening stopped for event with multiple callbacks';

$count = 0;
$listener->stop_listening;
$listener->listen_to($handler, 'test-event', $cb);
$listener->listen_to($handler, 'test-event', sub { goto &$cb });
$listener->stop_listening(undef, 'test-event', $cb);
$handler->trigger('test-event');
is $count, 1, 'one callback triggered after listening stopped for one callback with two callbacks registered';

$count = 0;
$listener->stop_listening;
$listener->listen_to($handler, 'test-event', $cb);
$listener->listen_to($handler, 'different-event', $cb);
$listener->stop_listening(undef, 'test-event', $cb);
$handler->trigger('test-event different-event');
is $count, 1, 'one callback triggered after listening stopped for event with callback registered for two events';

{
    my $listener = test_handler();
    dies_ok { $listener->stop_listening(1, 'event', sub {}) };
    dies_ok { $listener->stop_listening({}, 'event', sub {}) };

    my $obj = bless {}, __PACKAGE__;
    dies_ok { $listener->stop_listening($obj, 'event', sub {}) };
}


done_testing;
