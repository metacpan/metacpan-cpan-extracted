use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Test::Backbone::Events::Utils;

my $handler = test_handler();

my %triggered;
my $first  = sub { $triggered{first}++  };
my $second = sub { $triggered{second}++ };

$handler->on('test-event', $first);
$handler->on('test-event', $second);

$handler->off('test-event', $first);
$handler->trigger('test-event');
ok !$triggered{first}, 'skipped first callback after turning it off explicitly';
is $triggered{second}, 1, 'triggered second callback';

%triggered = ();
$handler->off('test-event');
$handler->trigger('test-event');
ok !%triggered, 'skipped all callbacks after calling off with only event name';

%triggered = ();
$handler->on('test-event', $first);
$handler->off();
$handler->trigger('test-event');
ok !%triggered, 'skipped all callbacks after calling off with no arguments';

%triggered = ();
$handler->on('test-event', $first);
$handler->on('test-event', $second);
$handler->off(undef, $second);
$handler->trigger('test-event');
is $triggered{first}, 1, 'triggered callback after calling off with different callback';
ok !$triggered{second}, 'skipped callbacks after calling off with callback';

done_testing;
