package AnyEvent::Promises;
$AnyEvent::Promises::VERSION = '0.06';
use strict;
use warnings;

# ABSTRACT: simple implementation of Promises/A+ spec


use Exporter 'import';
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(deferred merge_promises settle_promises is_promise make_promise);

use AnyEvent::Promises::Deferred;

sub deferred {
    return AnyEvent::Promises::Deferred->new();
}

sub make_promise {
    my $arg = shift;

    return $arg if is_promise($arg);

    my $d = deferred();
    if ( ref $arg && ref $arg eq 'CODE' ) {
        $d->resolve;
        return $d->promise->then($arg);
    }
    else {
        $d->resolve($arg);
        return $d->promise;
    }
}

sub merge_promises {
    my @promises = @_;

    my $d    = deferred();
    my $left = @promises;
    my @result;
    for my $i ( 0 .. $#promises ) {
        $promises[$i]->then(
            sub {
                # only the first value is taken into consideration
                $result[$i] = $_[0];
                --$left or $d->resolve(@result);
            },
            sub {
                $d->reject(@_);
            }
        );
    }
    if (!$left){
        # is true only when @promises is empty
        $d->resolve;
    }
    return $d->promise;
}

# actually is_thenable
sub is_promise {
    my ($cand) = @_;
    return blessed($cand) && $cand->can('then');
}

sub settle_promises {
    my @promises = shift;

    my $d    = deferred();
    my $left = @promises;

    my $cb = sub { --$left or $d->resolve(@promises); };
    $_->then( $cb, $cb ) for @promises;
    return $d->promise;
}

1;
    
# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:

__END__

=pod

=head1 NAME

AnyEvent::Promises - simple implementation of Promises/A+ spec

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use AnyEvent::Promises qw(deferred merge_promises);
    use AnyEvent::HTTP;
    use JSON qw(decode_json encode_json);

    sub wget {
        my ($uri) = @_;
        my $d = deferred;
        http_get $uri => sub {
            my ( $body, $headers ) = @_;
            $headers->{Status} == 200
                ? $d->resolve( decode_json($body) )
                : $d->reject('receiving data failed with status: '.  $headers->{Status} );
        };
        return $d->promise;
    }

    sub wput {
        my ($uri, $data) = @_;
        my $d = deferred;

        http_put $uri, body => encode_json($data) => sub {
            my ( $body, $headers ) = @_;
            $headers->{Status} == 200 || $headers->{Status} == 204
                ? $d->resolve( $body? decode_json($body) )
                : $d->reject('putting data failed with status: '.  $headers->{Status} );
        };
        return $d->promise;
    }

    my $cv = AnyEvent->condvar;
    merge_promises(
        wget('http://rest.api.example.com/customer/12345'),
        wget('http://rest.api.example.com/order/2345'),
        wget('http://rest.api.example.com/payment/3456')
    )->then(
        sub {
            my ($customer, $order, $payment) = @_;

            my $data = mix_together($customer, $order, $payment);
            return wput('http://rest2.api.example.com/aggregate/567', $data);
        }
    )->then(
        sub {
            # do something after the data are send
        },
        sub {
            # do something with the error
            # the error can be from wget as well as from wput 
        }
    );
        
    
    my $cv = AE::cv;
    # the condvar has to be finished somehow
    $cv->recv;

=head1 DESCRIPTION

AnyEvent::Promises is an implementation of the Promise pattern for
asynchronous programming - see L<http://promises-aplus.github.io/promises-spec/>.

Promises are the way how to structure your asynchronous code to avoid 
so called callback hell. 

=head1 METHODS

There are two classes of objects - deferred objects and promise objects. 
Both classes are "private", the objects are created by calling functions 
from L<AnyEvent::Promises>.

Typically a producer creates a deferred object, so it can resolve or reject
it asynchronously while returning the consumer part of deferred object (the
promise) synchronously to the consumer.

The consumer can synchronously "install handlers" on promise object 
to be notified when the underlying deferred object is resolved or rejected.

The deferred object is created via C<deferred> function (see EXPORTS).

The promise object is typically created via C<< $deferred->promise >>
or C<< $promise->then >>.

=head2 Methods of deferred (producers)

=over 4

=item C<promise>

Returns the promise for the deferred object.

=item C<resolve(@values)>

Resolve the deferred object with values. The argument list may be empty.

=item C<reject($reason)>

Reject the deferred object with a reason (exception). The C<$reason>
argument is required and must be true (in Perl sense).

A deferred object can be resolved or rejected once only.
Any subsequent call of C<resolve> or C<reject> is silently ignored.

=back

=head2 Methods of promise 

The promise object is a consumer part of deferred object.
Each promise has an underlying deferred object.

The promise is fulfilled when C<resolve> was called on the underlying deferred object.
The values of promise are simply the arguments of C<< $deferred->resolve >>.

The promise is rejected when C<reject> was called on the underlying deferred object.
The reason of promise is simply the argument of C<< $deferred->reject >>.

=over 4

=item C<then($on_fulfilled, $on_rejected)>

The basic method of a promise. This method returns a new promise. 

Each of C<$on_fulfilled> and C<$on_rejected> arguments is either coderef or undef. 

    my $pp = $p->then($on_fulfilled, $on_rejected);

The C<$pp> is fulfilled or rejected after C<$p> is fulfilled or rejected 
according to following rules:

If the C<$p> is fulfilled and $on_fulfilled is not a coderef (it is undef,
another value has no meaning), then C<$pp> is fulfilled with the same values
as C<$p>.

If the C<$p> is rejected and $on_rejected is not a coderef (it is undef,
another value has no meaning), then C<$pp> is rejected with the same reason
as C<$p>.

If the C<$p> is fulfilled, then $on_fulfilled handler is called with the values 
of C<$p> as an arguments.

If the C<$p> is rejected, then $on_rejected handler is called with the
rejection reason of C<$p> as an argument.

The handler (either C<$on_fulfilled> or C<$on_rejected>) is called in
a list context so it can return multiple values (here it differs from JavaScript
implementation). 

If the handler throws an exception, then C<$pp> is rejected with the
exception.

If the handler does not throw an exception and does not return a
promise, then C<$pp> is fulfilled with the values returned by the handler.

If the handler returns a promise, then C<$pp> is fulfilled/rejected
when the promise returned is fulfilled/rejected with the same values/reason.

It must be stressed that any handler is called outside of current stack 
in the "next tick" of even loop using C<< AnyEvent->postpone >>. 
It implies that without an event loop running now or later the handler is never called.

See example:

    my $d = deferred();
    $d->resolve(10);
    my $p = $d->promise->then(sub { 2 * shift() });
    warn $p->state; # yields 'pending' because the handler is yet to be called 
    warn $p->value; # yield undef for the same reason

The behaviour of C<then> in JavaScript is more precisely described 
here: L<http://promises-aplus.github.io/promises-spec/#the__method>.

=item C<sync([$timeout])>

    use AnyEvent::Promises qw(make_promise deferred);
    
    make_promise(8)->sync; # returns 8
    make_promise(sub { die "Oops" })->sync; # dies with Oops

    deferred()->promise->sync; # after 5 seconds dies with "TIMEOUT\n"
    deferred()->promise->sync(10); # after 10 seconds dies with "TIMEOUT\n"

Runs the promise synchronously. Runs new event loop which is finished
after $timeout (default 5) seconds or when the promise gets fulfilled 
or rejected.

If the promise gets fulfilled before timeout, returns the values of the promise.
If the promise gets rejected before timeout, dies with the reason of the promise.
Otherwise dies with C<TIMEOUT> string.

=item C<values>

If the promise was fulfilled, returns the values the underlying deferred object was resolved with.
If the promise was not fulfilled (was rejected or it is still pending), returns an empty list.

=item C<value>

The first element from values the underlying deferred object was resolved with.
If the promise was not fulfilled (was rejected or it is still pending), returns undef.

Having

    my $d = deferred();
    $d->resolve( 'a', 20 );
    my $p = $d->promise;
    $p->values;    # (returns ('a', 20))
    $p->value;     #  (returns 'a')

=item C<reason>

If the promise was rejected, returns the reason the underlying deferred object was resolved with.
If the promise was not rejected (was fulfilled or it is still pending) returns undef.

=item C<state>

Returns either B<pending>, B<fulfilled>, B<rejected>.

=item C<is_pending>

Returns true when the promise was neither fulfilled nor rejected.

=item C<is_fulfilled>

Returns true when the promise was fulfilled.

=item C<is_rejected>

Returns true when the promise was rejected.

=back

=head1 EXPORTS

All functions are exported on demand.

=over 4

=item C<deferred()>

Returns a new deferred object.

=item C<merge_promises(@promises)>

Accepts a list of promises and returns a new promise.

After any of the promises is rejected, the resulting promise
is rejected with the same reason as the first rejected promise.

After all of the promises are fulfilled, the resulting promise is
fulfilled with values being the list of C<< $promise->value >>
in order they are passed to C<merge_promises>

    my $d1 = deferred();
    my $d2 = deferred();
    my $d3 = deferred();
    $d1->resolve( 'A', 'B' );
    $d2->resolve;
    $d3->resolve( 3   );

    merge_promises( $d1->promise, $d2->promise, $d3->promise )->then(
        return @_;    # yields ('A', undef, 3)
    );

When called with empty list of promises returns promise which is resolved with empty list.

=item C<make_promise($arg)>

Shortcut for creating promises.

If C<$arg> is a promise, then C<make_promise> returns it.

If C<$arg> is a coderef, then C<make_promise> is equivalent to:

    my $d = deferred();
    $d->resolve();
    $d->promise->then($arg);

otherwise it is an equivalent to:

    my $d = deferred();
    $d->resolve($arg);
    $d->promise;

=item C<is_promise($arg)>

Returns true if the argument is a promise (object with method C<then>).

=back

=head1 SEE ALSO

=over 4 

=item L<AnyEvent>

To use this module it is necessary to have basic understanding of L<AnyEvent> event loop.

=item L<Promises>

Although L<AnyEvent::Promises> is similar to L<Promises> 
(and you can use its more thorough documentation to understand the concept of promises)
there are important differences. 

AnyEvent::Promises does not work without running event loop 
based on L<AnyEvent>. All C<$on_fulfilled>, C<$on_rejected> handlers 
(arguments of C<then> method) are run in "next tick" of event loop
as is required in 2.2.4 of the promises spec L<< http://promises-aplus.github.io/promises-spec/#point-39 >>.

There is also a crucial difference in C<$on_reject> handler behaviour
(exception handling). Look at

    my $d = deferred();
    $d->reject($reason);
    my $p = $d->promise->then(
        sub { },
        sub {
            return @_;
        }
    );

    $p->then(
        sub {
            warn "Code here is called when using AnyEvent::Promises";
        },
        sub {
            warn "Code here is called when using Promises";
        }
    );

With C<Promises> the C<$p> promise is finally rejected with C<$reason>,
while with C<AnyEvent::Promises> the C<$promise> is finally fulfilled
with C<$reason>, because the exception was handled (the handler did not
throw an exception).

=item L<https://github.com/kriskowal/q/wiki/API-Reference>

Here I shamelessly copied the ideas from.

=back

=head1 AUTHOR

Roman Daniel <roman.daniel@davosro.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
