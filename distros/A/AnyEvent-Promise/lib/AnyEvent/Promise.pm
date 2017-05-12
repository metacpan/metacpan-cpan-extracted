package AnyEvent::Promise;

use 5.008;
use strict;
use warnings FATAL => 'all';

use AnyEvent;
use Try::Tiny qw//;
use Carp;

=head1 NAME

AnyEvent::Promise - Evented promises

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Avoid the evented pyramid of doom!

    use AnyEvent::Promise;
    use AnyEvent::Redis;

    my $redis = AnyEvent::Redis->new();

    my $p = promise(sub {
        $redis->get('test');
    })->then(sub {
        $redis->set('test', shift);
    })->then(sub {
        $redis->get('test');
    })->then(sub {
        say shift;
    })->catch(sub {
        say 'I failed!';
        say @_;
    })->fulfill;

=head1 DESCRIPTION

L<AnyEvent::Promise> allows evented interfaces to be chained, taking away some
of the redundancy of layering L<AnyEvent> condition variable callbacks.

A promise is created using L<AnyEvent::Promise::new|/new> or the exported
L</promise> helper function. These will both return a promise instance and add
the callback function as the start of the promise chain. Each call to L</then>
on the promise instance will add another subroutine which returns a condition
variable to the chain.

The promise callback chain won't start until L</condvar> or L</fulfill> is
called on the instance. Calling L</condvar> or L</cv> will start the callback
chain and return the promise guarding condvar, which is fulfilled after the last
callback on the chain returns. Similarily, L</fulfill> will start the chain, but
will block until the guarding condvar is fulfilled.

Errors in the callbacks can be caught by setting an exception handler via the
L</catch> method on the promise instance. This method will catch exceptions
raised from L<AnyEvent> objects and exceptions raised in blocks provided to
L</then>. If an error is encountered in the chain, an exception will be thrown
and the rest of the chain will be skipped, jumping straight to the catch
callback.

=head1 EXPORT

=head2 promise($cb)

Start promise chain with callback C<$cb>. This function is a shortcut to
L<AnyEvent::Promise::new|/new>, and returns a promise object with the callback
attached.

=cut
sub promise { AnyEvent::Promise->new(@_) }

sub import {
    no strict 'refs';  ## no critic (ProhibitNoStrict)
    *{caller() . '::promise'} = \&promise;
}

=head1 METHODS

=head2 new($cb)

Create an instance of a promise, start the chain off with callback C<$cb>. See
L</then> for information on passing in a callback and condvar.

=cut
sub new {
    my ($class, $cb) = @_;

    my $self = bless {
        guard => undef,
        initial => undef,
        fulfill => undef,
        reject => undef,
        rejected => 0
    }, $class;

    $self->{guard} = AnyEvent->condvar;
    $self->{initial} = AnyEvent->condvar;

    my $reject = AnyEvent->condvar;
    $reject->cb(sub {
        carp shift->recv;
        $self->{guard}->send;
    });
    $self->{reject} = $reject;

    $self->then($cb);

    return $self;
}

=head2 then($cb)

Add callback C<$cb> on to the promise chain.

This callback will receive the return of the previous callback -- i.e. the
callback will receive the value sent by the previous condvar directly. In order
to continue the promise chain, the callback should return a condvar.

Instead of:

    my $cv = $redis->get('test');
    $cv->cb(sub {
        my $ret = shift->recv;
        my $cv2 = $redis->set('test', $ret);
        $cv2->cb(sub {
            my $cv3 = $redis->get('test');
            $cv3->cb(sub {
                my $ret3 = shift->recv;
                printf("Got a value: %s\n", $ret3);
            });
        });
    });
    $cv->recv;

.. a promise chain can be used, by chaining calls to the L</then> method:

    my $promise = AnyEvent::Promise->new(sub {
        $redis->get('test');
    })->then(sub {
        my $val = shift;
        $redis->set('test', $val);
    })->then(sub {
        $redis->get('test');
    })->then(sub {
        my $val = shift;
        printf("Got a value: %s\n", $val)
    })->fulfill;

=cut
sub then {
    my ($self, $fn) = @_;

    return $self
      if ($self->{rejected});

    $self->{guard}->begin;

    my $cvin = $self->{fulfill};
    if (!defined $cvin) {
        $cvin = $self->{initial};
    }

    my $cvout = AnyEvent->condvar;
    $cvin->cb(sub {
        my $thenret = shift;
        Try::Tiny::try {
            my $ret = $thenret->recv;
            my $cvret = $fn->($ret);
            if ($cvret and ref $cvret eq 'AnyEvent::CondVar') {
                $cvret->cb(sub {
                    my $ret_inner = shift;
                    Try::Tiny::try {
                        $cvout->send($ret_inner->recv);
                        $self->{guard}->end;
                    }
                    Try::Tiny::catch {
                        $self->{rejected} = 1;
                        $self->{reject}->send(@_);
                    }
                });
            }
            else {
                $cvout->send($cvret);
                $self->{guard}->end;
            }
        }
        Try::Tiny::catch {
            $self->{rejected} = 1;
            $self->{reject}->send(@_);
        }
    });
    $self->{fulfill} = $cvout;

    return $self;
}

=head2 catch($cb)

Catch raised errors in the callback chain. Exceptions in the promise chain will
jump up to this catch callback, bypassing any other callbacks in the promise
chain. The error caught by L<Try::Tiny> will be sent as arguments to the
callback C<$cb>.

=cut
sub catch {
    my ($self, $fn) = @_;

    $self->{reject}->cb(sub {
        my @err = shift->recv;
        $fn->(@err);
        $self->{guard}->send;
    });

    return $self;
}

=head2 condvar(...)

Trigger the start of the promise chain and return the guard condvar from the
promise. The guard condvar is fulfilled either after the last callback returns
or an exception is encountered somewhere in the chain.

All arguments passed into L</condvar> are sent to the first condvar in the
promise chain.

=cut
sub condvar {
    my $self = shift;
    $self->{initial}->send(@_);
    $self->{fulfill}->cb(sub {
        $self->{guard}->send;
    });
    return $self->{guard};
};

=head2 cv(...)

Alias of L</condvar>

=cut
sub cv { condvar(@_) }

=head2 fulfill(...)

Similar to L</condvar>, trigger the start of the promise chain, but C<recv> on
the returned condvar as well.

=cut
sub fulfill {
    my $self = shift;
    my $cv = $self->condvar(@_);
    $cv->recv;
}

=head1 AUTHOR

Anthony Johnson, C<< <aj at ohess.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Anthony Johnson.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
