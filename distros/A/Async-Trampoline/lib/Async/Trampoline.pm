use strict;
use warnings;
use utf8;

package Async::Trampoline;

BEGIN {
    ## no critic
    our $VERSION = '0.001000';
    $VERSION = eval $VERSION;
    ## use critic
}

use XSLoader;
BEGIN { XSLoader::load __PACKAGE__, our $VERSION }

use Async::Trampoline::Scheduler;

use Exporter 'import';

our %EXPORT_TAGS = (
    all => [qw/
        await
        async
        async_value
        async_error
        async_cancel
        async_yield
    /],
);

our @EXPORT_OK = @{ $EXPORT_TAGS{all} };

use overload
    fallback => 1,
    q("") => sub {
        my ($self) = @_;
        return $self->to_string;
    };

sub gen_collect :method {
    my ($gen) = @_;
    my @acc;
    return $gen
        ->gen_foreach(sub { push @acc, @_; return async_value })
        ->value_then(async_value \@acc);
}

1;

__END__

=encoding utf8

=head1 NAME

Async::Trampoline - Trampolining functions with async/await syntax

=head1 SYNOPSIS

=for test
    use Test::Output;
    use feature 'say';

    use Async::Trampoline qw(
        await
        async async_value async_error async_cancel
        async_yield
    );

    # creating asyncs
    $async = async_value 1, 2, 3;
    $async = async_error "oops";
    $async = async_cancel;
    $async = async { ...; return $new_async };

=for test
    $async = async_value 1, 2, 3;

    # running asyncs
    @result = $async->run_until_completion;

=for test
    is "@result", "1 2 3";

=for test
    $other_async = async { async_value "other async" };
    $new_async = async_value "new async";
    $x = async_value "x";
    $y = async_value "y";

    # combining asyncs
    $async = $other_async->await(sub {
        my (@values) = @_;
        # ...
        return $new_async;
    });
    $async = await [$x, $y] => sub {
        my (@x_and_y_values) = @_;
        # ...
        return $new_async;
    };
    $async = $x->complete_then($y);
    $async = $x->resolved_or($y);
    $async = $x->resolved_then($y);
    $async = $x->value_or($y);
    $async = $x->value_then($y);
    $async = $x->concat($y);

    # generators
    $gen = async_yield async_value(1, 2, 3) => sub {
        # ...
        return $next_generator;
    };
    $gen = $gen->gen_map(sub {
        my (@values) = @_;
        # ...
        return $new_async;
    });
    $async = $gen->gen_foreach(sub {
        my (@values) = @_;
        return async_cancel if not @values;  # like "last" in Perl
        # ...
        return async_value;  # like "next" in Perl
    });
    $async = $gen->gen_collect;

    # misc
    $str = $async->to_string;
    $bool = $async->is_complete;
    $bool = $async->is_cancelled;
    $bool = $async->is_error;
    $bool = $async->is_value;

=head1 DESCRIPTION

Trampolines are a functional programming technique
to implement complex control flow:
Instead of returning a result from a function,
we can return another function that will at some point return a result.
The trampoline keeps invoking the returned function
until a result is returned.
Importantly, such trampolines eliminate tail calls.

This programming style is powerful but inconvenient
because you tend to get callback hell.
This module implements simple Futures with an async/await syntax.
Instead of nesting the callbacks, we can now chain callbacks more easily.

This module was initially created
in order to write recursive algorithms around compiler construction:
recursive-descent parsers and recursive tree traversal.
However, it is certainly applicable to other problems as well.
The module is written in C++ to keep runtime overhead minimal.

=head2 Example: loop

Synchronous/imperative:

    my @items;

    my $i = 5;
    while ($i) {
        push @items, $i--;
    }

=for test
    is "@items", "5 4 3 2 1", q(Synchronous/imperative);

Synchronous/recursive:

    sub loop {
        my ($items, $i) = @_;
        return $items if not $i;
        push @$items, $i--;
        return loop($items, $i);  # may lead to deep recursion!
    }

    my $items = loop([], 5);

=for test
    is "@$items", "5 4 3 2 1", q(Synchronous/recursive);

Async/recursive:

    sub loop_async {
        my ($items, $i) = @_;
        return async_value $items if not $i;
        push @$items, $i--;
        return async { loop_async($items, $i) };
    }

    my $items = loop_async([], 5)->run_until_completion;

=for test
    is "@$items", "5 4 3 2 1", q(Async/recursive);

Async/generators:

    sub loop_gen {
        my ($i) = @_;
        return async_cancel if not $i;
        return async_yield async_value($i) => sub {
            return loop_gen($i - 1);
        };
    }

    my $items = loop_gen(5)->gen_collect->run_until_completion;

=for test
    is "@$items", "5 4 3 2 1", q(Async/generators);

=head1 ASYNC STATES

Each Async exists in one of these states:

=for test ignore

    Async
    +-- Incomplete
        +-- ... (internal)
    +-- Complete
        +-- Cancelled
        +-- Resolved
            +-- Error
            +-- Value

=for test

In B<Incomplete> states, the Async will be processed in the future.
At some point, the Async will transition to a completed state.

In C<async> and C<await> callbacks,
the Async will be updated to the state of the return value of that callback.

B<Completed> states are terminal.
The Asyncs are not subject to further processing.

A B<Cancelled> Async represents an aborted computation.
They have no value.
Cancellation is not an error,
but C<run_until_completion()> will die when the Async was cancelled.
You can cancel a computation via the C<async_cancel> constructor.
Cancellation is useful to abort loops,
or to fall back to an alternative with
C<< $may_cancel->resolved_or($alternative) >>.

B<Resolved> Asyncs are Completed Asyncs that finished their computation
and have a value, either an Error or a Value upon success.

An B<Error> Async indicates that a runtime error occurred.
Error Asyncs can be created with the C<async_error> constructor,
or when a callback throws.
The exception will be rethrown by C<run_until_completion()>.

A B<Value> Async contains a list of Perl values.
They can be created with the C<async_value> constructor.
The values will be returned by C<run_until_completion()>.
To access the values of an Async, you can C<await> it.

=head1 CREATING ASYNCS

=head2 async

    $async = async { ... };

Create an Incomplete Async with a code block.
The callback must return an Async.
When the Async is evaluated,
this Async is updated to the state of the returned Async.

=head2 async_value

    $async = async_value @values;

Create a Value Async containing a list of values.
Use this to return values from an Async callback.

=head2 async_error

    $async = async_error $error;

Create an Error Async with the specified error.
The error may be a string or error object.
Use this to fail an Async.
Alternatively, you can C<die()> inside the Async callback.

=head2 async_cancel

    $async = async_cancel;

Create a Cancelled Async.
Use this to abort an Async without using an error.

=head1 COMBINING ASYNCS

=head2 await

=for test
    $dependency = async { async_value 1,2, 3 };
    @dependencies = (async_value(1), async_value(), async_value(3));

    $async = $dependency->await(sub {
        my (@result) = @_;
        # ...
        return $new_async;
    });

    $async = await $dependency => sub {
        my (@result) = @_;
        # ...
        return $new_async;
    };

    $async = await [@dependencies] => sub {
        my (@results) = @_;
        # ...
        return $new_async;
    };

Wait until the C<$dependency> or C<@dependencies> Asyncs have a value,
then call the callback with the values as arguments.
If a dependency was cancelled or has an error,
the async is updated to that state.
The callback must return an Async.
Use this to chain Asyncs.
It does not directly return the values.

=head2 resolved_or

=head2 value_or

=for test
    $first_async = async { async_value };
    $alternative_async = async { async_value };
    $second_async = $alternative_async;

    $async = $first_async->resolved_or($alternative_async);
    $async = $first_async->value_or($alternative_async);

Evaluate the C<$first_async>.
Upon success, the Async is updated to the state of the C<$first_async>.
On failure, the C<$second_async> is evaluated instead.
This creates a new Async that will be updated
when the dependencies become available.

B<resolved_or> succeeds on Value or Error, and fails on Cancelled.
Use this as a fallback against cancellation.

B<value_or> only succeeds on Value, and fails on Cancelled or Error.
Use this as a try-catch to provide default values upon errors.

=head2 complete_then

=head2 resolved_then

=head2 value_then

    $async = $first_async->complete_then($second_async);
    $async = $first_async->resolved_then($second_async);
    $async = $first_async->value_then($second_async);

Evaluate the C<$first_async>.
Upon success, the C<$second_async> is evaluated.
On failure, the Async is updated to the state of the C<$first_async>.
This creates a new Async that will be updated
when the dependencies become available.

B<complete_then> always succeeds (Cancelled, Error, Value).

B<resolved_then> succeeds on Error or Value, and fails on Cancelled.

B<value_then> succeeds on Value, and fails on Cancelled or Error.
With regards to error propagation,
C<< $x->value_then($y) >>
behaves just like
C<< $x->await(sub { return $y } >>.

Use these functions to sequence actions on success and discarding their value.
They are like a semicolon C<;> in Perl,
but with different levels of error propagation.
You may want to sequence Asyncs if any Async causes side effects.

=head2 concat

    $async = $first_async->concat($second_async);

If both asyncs evaluate to Values, concatenate the values.

B<Example>:

    $async = (async_value 1, 2, 3)->concat(async_value 4, 5);
    #=> async_value 1, 2, 3, 4, 5

=for test {
    my @result = $async->run_until_completion;
    is "@result", "1 2 3 4 5", q(concat());
}

=head1 GENERATORS

A B<Generator> describes an Async
that has a continuation Async as its first value.
This continuation can be awaited to get the next continuation + value.
If the generator is Cancelled, no further items are available.
Errors are propagated.

Generators are useful for yielding a stream of values.

You can use C<async_yield()> to conveniently return a value with a continuation.
The C<gen_*()> Async methods can process generator streams.
They will fail at runtime when the Async is not a valid generator.

The most flexible way to handle generators is to C<await()> them.
However, many use cases are better served by more specialized functions.

B<Example:> a count down generator:

    sub count_down_generator {
        my ($i) = @_;
        return async_cancel if $i < 0;
        return async_yield async_value($i) => sub {
            return count_down_generator($i - 1);
        };
    }

    my $countdown_gen = count_down_generator(10);

B<Example:> transforming a stream:

    $countdown_gen = $countdown_gen->gen_map(sub {
        my ($i) = @_;
        return async_value "ignition" if $i == 3;
        return async_value "liftoff"  if $i == 0;
        return async_value $i;
    });

=for test
    $result = $countdown_gen->gen_collect->run_until_completion;
    is "@$result", "10 9 8 7 6 5 4 ignition 2 1 liftoff", q(countdown map);

B<Example:> consuming a stream:

    my $finished_async = $countdown_gen->gen_foreach(sub {
        my ($i) = @_;
        say $i;
        return async_value;  # request next item
    });

=for test
    stdout_is { $result = $finished_async->run_until_completion }
        (join q() => map "$_\n" => qw( 10 9 8 7 6 5 4 ignition 2 1 liftoff )),
        q(countdown stdout);
    is $result, undef, q(countdown result);

B<Example>: repeating each element:

    sub repeat_gen {
        my ($gen) = @_;
        return $gen->await(sub {
            my ($continuation, $x) = @_;
            return async_yield async_value($x) => sub {
                return async_yield async_value($x) => sub {
                    repeat_gen($continuation);
                };
            };
        });
    }

=for test
    $result = repeat_gen(count_down_generator(2))
        ->gen_collect
        ->run_until_completion;
    is "@$result", "2 2 1 1 0 0", q(repetition);

=head2 async_yield

    $generator = async_yield $async => sub { return $next_generator }

Yield a value from a generator function.
The C<$async> contains the value or state you want to yield.
The callback will be executed to yield the next value.
It receives no arguments.
It must return a valid generator.

=head2 gen_map

    $generator = $generator->gen_map(sub {
        my (@values) = @_;
        # ...
        return $new_async;
    });

Transform the values yielded by a generator.
The callback receives the values of the current item as parameters.
The callback must return an Async, usually a value.
It may also return C<async_cancel> to terminate the Generator,
or C<async_error>.

You cannot return multiple Asyncs (at most a multi-value Async).
Returning a Generator Async is not meaningful,
and it will be treated as an ordinary value.

=head2 gen_foreach

    $async = $generator->gen_foreach(sub {
        my (@values) = @_;
        # ...
        return async_value;
    });

Consume a generator.
The callback will be invoked with each item's values.
The callback may return an Async Value to receive the next value,
or may return an Async Error or Async Cancel to abort the loop.

The returned Async is
an empty Value when the loop completes successfully or was aborted,
and an Error when there was an error in the loop body or in the generator.

=head2 gen_collect

    $async = $generator->gen_collect;

Collects all items in an array ref.
This will consume the whole stream, so only works for finite streams.

=head1 OTHER FUNCTIONS

=head2 run_until_completion

=for test
    $async = async { async_value 1, 2, 3 };

    @result = $async->run_until_completion;

=for test
    is "@result", "1 2 3", q(run_until_completion());

Creates and event loop and blocks until the C<$async> is completed.
If it was cancelled, throws an exception.
If it was an error, rethrows that error.
If it was a value, the values are returned as a list.

This call should be used sparingly, usually once per program.
Sharing Asyncs between multiple event loops may lead to unexpected results.

If you want to use the results of an Async to continue within an Async context,
you usually want to C<await()> the Async instead.

=head2 to_string

    $str = $async->to_string;
    $str = "$async";

Low-level debugging stringification that displays Async identity and type.

=head2 is_complete

=head2 is_cancelled

=head2 is_resolved

=head2 is_error

=head2 is_value

    $bool = $async->is_complete;
    $bool = $async->is_cancelled;
    $bool = $async->is_resolved;
    $bool = $async->is_error;
    $bool = $async->is_value;

Inspect the state of an Async (see L<"Async States"|/"ASYNC STATES">).

=head1 WHAT THIS MODULE IS NOT

This module is not very well tested and battle-proven.
There are certainly still some bugs lurking around.

This module does not provide first-class corountines or async/await keywords.
It is just a library.
Check out the L<Future::AsyncAwait|Future::AsyncAwait> module instead.

This module does not provide first-class Future objects.
While Asyncs are Future-like, you cannot resolve an Async explicitly.
Check out the L<Future|Future> module instead.

This module does not implement an event loop.
The C<run_until_completion()> function does run a dispatch loop,
but there is no concept of events, I/O, or timers.
Check out the L<IO::Async|IO::Async> module instead.

This module is not thread-aware.
Handling the same Async on multiple threads is undefined behaviour.

This module does not detect infinite loops.
It is your responsibility to ensure
that Async dependencies don't form cycles.

This module does not guarantee any particular evaluation order.
If you need a specific sequence, you must encode it explicitly
(see L<Combining Asyncs|/"COMBINING ASYNCS">).
Note that the combinators do not declare
a partial order between one or more Asyncs,
but specify in which order
the dependencies of the combinator Async are evaluated.
E.g. in C<< $x->complete_then($y) >>, C<$y> may be evaluated first
if some other Async depends on C<$y> as well.

This module is not pure-Perl.
You will need a C++11 compiler to install it.

=head1 SUPPORT

Homepage: L<https://github.com/latk/p5-Async-Trampoline>

Bug Tracker: L<https://github.com/latk/p5-Async-Trampoline/issues>

=head1 AUTHOR

amon - Lukas Atkinson (cpan: AMON) <amon@cpan.org>

=head1 COPYRIGHT

Copyright 2017 Lukas Atkinson

This library is free software and may be distributed under the same terms as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
