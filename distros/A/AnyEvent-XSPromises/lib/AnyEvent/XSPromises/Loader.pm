package AnyEvent::XSPromises::Loader;
use 5.010;
use strict;
use warnings;

our $VERSION = '0.006';

use AnyEvent;

require XSLoader;
XSLoader::load('AnyEvent::XSPromises', $VERSION);

AnyEvent::XSPromises::___set_conversion_helper(sub {
    my $promise= shift;
    my $deferred= AnyEvent::XSPromises::deferred();
    my $called;
    eval {
        $promise->then(sub {
            return if $called++;
            $deferred->resolve(@_);
        }, sub {
            return if $called++;
            $deferred->reject(@_);
        });
        1;
    } or do {
        my $error= $@;
        if (!$called++) {
            $deferred->reject($error);
        }
    };
    return $deferred->promise;
});

# We do not use AE::postpone, because it sets a timer of 0 seconds. While that sounds great in
# theory, the underlying libraries (eg. epoll, used by EV) don't support 0 second timers, and
# so they get passed 1ms instead. To avoid actually waiting a millisecond every time, we write
# data onto a socket read by the event loop. Of course, these sockets need to be carefully managed
# in case the code does a fork, so we need to frequently check $$.
my ($AE_PID, $AE_WATCH, $PIPE_IN, $PIPE_OUT);
BEGIN { $AE_PID= -1; }

sub ___notify_callback {
    if ($$ != $AE_PID) {
        ___reset_pipe();
    } else {
        sysread $PIPE_IN, my $read_buf, 16;
    }

    # sort makes perl push a pseudo-block on the stack that prevents callback code from using
    # next/last/redo. Without it, an accidental invocation of one of those could cause serious
    # problems. We have to assign it to @useless_variable or Perl thinks our code is a no-op
    # and optimizes it away.
    my @useless_variable= sort { AnyEvent::XSPromises::___flush(); 0 } 1, 2;
}

sub ___reset_pipe {
    close $PIPE_IN if $PIPE_IN;
    close $PIPE_OUT if $PIPE_OUT;
    pipe($PIPE_IN, $PIPE_OUT);
    $AE_WATCH= AE::io($PIPE_IN, 0, \&___notify_callback);
    $AE_PID= $$;
}

AnyEvent::XSPromises::___set_backend(sub {
    ___reset_pipe() if $$ != $AE_PID;
    syswrite $PIPE_OUT, "\0";
});

1;
