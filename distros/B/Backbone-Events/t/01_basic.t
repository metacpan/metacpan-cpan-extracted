use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Test::Backbone::Events::Utils;

my $handler = test_handler();

my $triggered = 0;
$handler->on('wanted', sub { $triggered++ });

$handler->trigger('not_wanted');
is $triggered, 0, 'callback not triggered on unwanted event';

$handler->trigger('wanted');
is $triggered, 1, 'callback triggered on wanted event';


my $second_trigger = 0;
$handler->on('wanted', sub { $second_trigger++ });

$triggered = 0;
$handler->trigger('wanted');
is $triggered, 1, 'triggered first callback when after adding second callback';
is $second_trigger, 1, 'triggered second callback';

done_testing;
