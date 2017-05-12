use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Test::Backbone::Events::Utils;

{
    my $handler = test_handler();

    my $called_all = 0;
    $handler->on('all', sub { $called_all++ });
    $handler->trigger('something-random-'.rand);

    is $called_all, 1, 'callback registered for all triggered on random event';
}

{
    my $handler = test_handler();

    my @args_on_all;
    $handler->on('all', sub { @args_on_all = @_ });

    my $event = 'random-event-'.rand;
    my @args  = map rand, 1 .. int(rand 10);
    $handler->trigger($event, @args);
    is_deeply \@args_on_all, [$event, @args], 'all callback is triggered with event name and original args';
}

done_testing;
