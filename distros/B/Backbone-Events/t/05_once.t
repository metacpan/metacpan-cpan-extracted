use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Test::Backbone::Events::Utils;

my $handler = test_handler();

my $triggered = 0;
$handler->once('once', sub { $triggered++ });

$handler->trigger('once');
is $triggered, 1, 'triggered once event on first trigger';

$triggered = 0;
$handler->trigger('once');
is $triggered, 0, 'did not trigger once event on second trigger';


$triggered = 0;
my $cb = sub { $triggered++ };
$handler->once('once', $cb);
$handler->off('once',  $cb);

$handler->trigger('once');
ok !$triggered. 'did not trigger once event after turning if off';

done_testing;
