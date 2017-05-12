# NAME

App::Environ - Simple environment to build applications using service locator
pattern

# SYNOPSIS

    use App::Environ;

    App::Environ->register( __PACKAGE__,
      initialize   => sub { ... },
      reload       => sub { ... },
      'finalize:r' => sub { ... },
    );

    App::Environ->send_event( 'initialize', qw( foo bar ) );
    App::Environ->send_event('reload');
    App::Environ->send_event( 'pre_finalize:r', sub {...} );
    App::Environ->send_event('finalize:r');

# DESCRIPTION

App::Environ is the simple environment to build applications using service
locator pattern. Allows register different application components that provide
common resources.

# METHODS

## register( $class, \\%handlers )

The method registers handlers for specified events. When some event have been
sent, registered event handlers will be processed in order in which they was
registered. If you want that event handlers have been processed in reverse
order, add postfix `:r` to event name. All arguments that have been specified
in `send_event` method (see below) are passed to called event handler. If in
the last argument is passed the callback, the handler must call it when
processing will be done. If the handler was called with callback and some error
occurred, the callback must be called with error message in first argument.

    App::Environ->register( __PACKAGE__,
      initialize => sub {
        my @args = @_;

        # handling...
      },
    );

## send\_event( $event \[, @args \] \[, $cb->( \[ $err \] ) \] )

Sends specified event to App::Environ. All handlers registered for this event
will be processed. Arguments specified in `send_event` method will be passed
to event handlers. If the callback is passed in the last argument, event
handlers will be processed in asynchronous mode.

    App::Environ->send_event( 'initialize', qw( foo bar ) );

    App::Environ->send_event( 'pre_finalize:r'
      sub {
        my $err = shift;

        if ( defined $err ) {
          # error handling...

          return;
        }

        # success handling...
      }
    );

# SEE ALSO

[App::Environ::Config](https://metacpan.org/pod/App::Environ::Config)

Also see examples from the package to better understand the concept.

# AUTHOR

Eugene Ponizovsky, <ponizovsky@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (c) 2016-2017, Eugene Ponizovsky, <ponizovsky@gmail.com>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
