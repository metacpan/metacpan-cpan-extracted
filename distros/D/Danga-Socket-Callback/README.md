# NAME

Danga::Socket::Callback - Use Danga::Socket From Callbacks

# SYNOPSIS 

    my $danga = Danga::Socket::Callback->new(
      handle         => $socket,
      context        => { ... },
      on_read_ready  => sub { ... },
      on_write_ready => sub { ... },
      on_error       => sub { ... },
      on_signal_hup  => sub { ... },
    );

    Danga::Socket->EventLoop();

# DESCRIPTION

Love the fact that Perlbal, Mogilefs, and friends all run fast because of
Danga::Socket, but despise it because you need to subclass it every time?
Well, here's a module for all you lazy people.

Danga::Socket::Callback is a thin wrapper arond Danga::Socket that allows
you to set callbacks to be called at various events. This allows you to
define multiple Danga::Socket-based sockets without defining multiple
classes:

    my $first = Danga::Socket::Callback->new(
      hadle => $sock1,
      on_read_ready => \&sub1
    );

    my $second = Danga::Socket::Callback->new(
      hadle => $sock2,
      on_read_ready => \&sub2
    );

    Danga::Socket->EventLoop();

# METHODS

## new

Creates a new instance of Danga::Socket::Callback. Takes the following
parameters:

- handle

    The socket/handle to read from.

- context

    Arbitrary data to be shared between your app and Danga::Socket::Callback.

- on\_read\_ready

    Specify the code reference to be fired when the socket is ready to be read

- on\_write\_ready

    Specify the code reference to be fired when the socket is ready to be written

- on\_error

    Specify te code reference to be fired when there was an error

- on\_signal\_hup

    Specify the code reference to be fired when a HUP signal is received.

## event\_read

## event\_write

## event\_err

## event\_hup

Implements each method available from Danga::Socket. If the corresponding
callbacks are available, then calls the callback. Each callback receives
the Danga::Socket::Callback object.

For event\_write, if no callback is available, then the default event\_write
method from Danga::Socket is called.

# BUGS

Possibly. I don't claim to use 100% of Danga::Socket. If you find any,
please report them (preferrably with a failing test case)

# AUTHOR

Copyright (c) Daisuke Maki <daisuke@endeworks.jp>
All rights reserved.

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
