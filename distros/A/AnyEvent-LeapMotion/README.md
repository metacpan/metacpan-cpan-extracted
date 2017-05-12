# NAME

AnyEvent::LeapMotion - Perl interface to the Leap Motion Controller (via WebSocket)

# SYNOPSIS

    use AnyEvent;
    use AnyEvent::LeapMotion;

    my $leap = AnyEvent::LeapMotion->new(
        enable_gesture => 1,
        on_frame => sub {
            my $frame = shift;

            ...
        },
    );
    $leap->run;

    AE::cv->recv;

# DESCRIPTION

AnyEvent::LeapMotion is a simple interface to the Leap Motion controller. It receives tracking data through a WebSocket server.

# METHODS

- `my $leap = AnyEvent::LeapMotion->new()`

    Create an instance of AnyEvent::LeapMotion.

    - on\_frame : Sub
    - on\_error : Sub
    - host => '127.0.0.1' : Str
    - port => 6437 : Num
    - enable\_gesture => 0 : Bool

- `$leap->run()`

    Running an event loop.

# MOTIVATION

There is [Device::Leap](http://search.cpan.org/perldoc?Device::Leap) module on CPAN, but it is difficult to use and cannot get the gesture. So I made a module with simple interface.

# SEE ALSO

[WebSocket Communication](https://developer.leapmotion.com/documentation/javascript/supplements/Leap\_JSON.html)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>
