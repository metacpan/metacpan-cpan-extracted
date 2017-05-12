use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Test::Backbone::Events::Utils;

{
    my %triggered;
    my $first   = sub { $triggered{first}++  };
    my $second  = sub { $triggered{second}++ };
    my $handler = test_handler();

    $handler->on('one two', $first);
    $handler->trigger($_) for qw(one two);
    is $triggered{first}, 2, '';

    %triggered = ();
    $handler->trigger('one two');
    is $triggered{first}, 2, '';

    %triggered = ();
    $handler->off;
    $handler->on({
        one => $first,
        two => $second,
    });
    $handler->trigger($_) for qw(one two);
    is $triggered{first},  1;
    is $triggered{second}, 1;
}

{
    my %triggered;
    my $first    = sub { $triggered{first}++  };
    my $second   = sub { $triggered{second}++ };
    my $handler  = test_handler();
    my $listener = test_handler();

    $listener->listen_to($handler, 'one two', $first);
    $handler->trigger($_) for qw(one two);
    is $triggered{first}, 2, '';

    %triggered = ();
    $listener->stop_listening();
    $listener->listen_to($handler, {
        one => $first,
        two => $second,
    });
    $handler->trigger($_) for qw(one two);
    is $triggered{first},  1;
    is $triggered{second}, 1;
}

done_testing;
