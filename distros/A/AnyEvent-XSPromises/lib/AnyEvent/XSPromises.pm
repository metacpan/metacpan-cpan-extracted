package AnyEvent::XSPromises;

use 5.010;
use strict;
use warnings;

use AnyEvent::XSPromises::Loader;

use Exporter 'import';
our @EXPORT_OK= qw/collect deferred resolved rejected/;

sub resolved {
    my $d= deferred;
    $d->resolve(@_);
    return $d->promise;
}

sub rejected {
    my $d= deferred;
    $d->reject(@_);
    return $d->promise;
}

# XXX This is pure-perl, not XS like we promise our users.
sub collect {
    my $remaining= 0+@_;
    my @values;
    my $failed= 0;
    my $then_what= deferred;
    my $pending= 1;
    my $i= 0;
    for my $p (@_) {
        my $i= $i++;
        $p->then(sub {
            $values[$i]= [@_];
            if ((--$remaining) == 0) {
                $pending= 0;
                $then_what->resolve(@values);
            }
        }, sub {
            if (!$failed++) {
                $pending= 0;
                $then_what->reject(@_);
            }
        });
    }
    if (!$remaining && $pending) {
        $then_what->resolve(@values);
    }
    return $then_what->promise;
}

1;

=head1 NAME

AnyEvent::XSPromises - Another Promises library, this time implemented in XS for performance

=head1 SYNOPSIS

    use AnyEvent::XSPromises qw/deferred/;
    use AnyEvent::YACurl;

    sub do_request {
        my $request_args= @_;

        my $deferred= deferred;
        AnyEvent::YACurl->new({})->request(
            sub {
                my ($response, $error)= @_;
                if ($error) { $deferred->reject($error); return; }
                $deferred->resolve($response);
            },
            $request_args
        );

        return $deferred->promise;
    }

=head1 DESCRIPTION

This library provides a Promises interface, written in XS for performance, conforming to the Promises/A+ specification.

Performance may not immediately seem important, but when promises are used as the building block for sending thousands
of database queries per second from a single Perl process, those extra microseconds suddenly start to matter.

=head1 API

=head2 AnyEvent::XSPromises

=over

=item deferred()

C<deferred> is the main entry point for using promises. This function will return a Deferred Object that must be
resolved or rejected after some event completes.

    sub get_perl {
        my $d= deferred;
        http_get("https://perl.org", sub {
            $d->resolve(@_);
        });
        return $d->promise;
    }

=item collect(...)

C<collect> makes a promise out of a collection of other promises (thenables). If all inputs get resolved, the promise will
be resolved with the outputs of each. If any input gets rejected, the promise will be rejected with its reason.

Because of how context (array vs scalar) works in Perl, all outputs are wrapped in an arrayref.

    collect(
        resolved(1),
        resolved(2)
    )->then(sub {
        # @_ is now ( [1], [2] )
    })

=item resolved(...)

Shortcut for creating a promise that has been resolved with the given inputs

    resolved(5)->then(sub {
        my $five= shift;
    })

=item rejected(...)

Shortcut for creating a promise that has been rejected with the given inputs. See C<resolved>

=back

=head2 Deferred objects

=over

=item $d->promise()

Gets a thenable promise associated to the Deferred object.

    my $d= deferred;
    ...
    return $d->promise;

=item $d->resolve(...)

Resolves the deferred object (assigns a value). All associated promises will have their callback invoked in the next event
loop iteration.

=item $d->reject(...)

Rejects the deferred object (assigns a reason for why it failed). All associated promises will have their callback invoked
in the next event loop iteration.

=item $d->is_in_progress()

Returns true iff the C<reject> or C<resolve> method has not been called yet. Useful for racing multiple code paths to
resolve/reject a single deferred object, like one would do to build a timeout.

    sub get_with_timeout {
        my $d= deferred;
        my $timer; $timer= AE::timer 1, 0, sub {
            undef $timer;
            $d->reject("Timed out") if $d->is_in_progress;
        };

        http_get("https://perl.org", sub {
            my $result= shift
            $d->resolve($result) if $d->is_in_progress;
        });

This method is intentionally not available on promise objects.

=back

=head2 Promise objects

=over

=item $p->then($on_resolve, $on_reject)

Registers the given C<on_resolve> and/or C<on_reject> callback on the promise, and returns a new promise.

=item $p->catch($on_reject)

Similar to C<then>, but only takes C<on_reject>.

=item $p->finally($on_finally)

Register a callback on the promise that will be invoked once it completes. The callback is quietly executed but cannot
change the output or status of the promise. Returns a promise that will be resolved/rejected based on the original promise.

=back

=head1 COMPARISON TO OTHER PROMISES LIBRARIES

=over

=item Promises

L<Promises> is a pure-Perl Promises implementation that allows selecting one of multiple event loop backends. However,
this backend is defined globally and the documentation suggests that it would be best if only the application developer
picks a backend. This means that libraries cannot know up front which event loop backend they have to use, and they need
to support all event loops or the library would break if a different event loop is chosen. This has lead library authors
to mandate that the selected backend is AnyEvent, defying the purpose of backend selection other than for usage in
scripts that do not need compatibility with other code such as libraries from CPAN.

The library also trades performance and resilience for a few features that are not needed to implement the Promises/A+
specification.

Promises from this library are compatible with ours if the backend is set to C<AE> or C<AnyEvent>.

=item AnyEvent::Promises

L<AnyEvent::Promises> is another pure-Perl Promises implementation. It is a lot simpler than L<Promises>, but comes with
performance implications, and has not been very hardened against developer error. Since it is also based on AnyEvent,
and comes with an identical C<< then($on_resolve, $on_reject) >> API, its promises are fully compatible with ours and
can be freely passed around between the two libraries if necessary.

=back

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>
