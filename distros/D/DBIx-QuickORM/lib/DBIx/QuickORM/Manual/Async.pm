package DBIx::QuickORM::Manual::Async;
use strict;
use warnings;

our $VERSION = '0.000026';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Async - Asynchronous, aside, and forked queries in
L<DBIx::QuickORM>.

=head1 DESCRIPTION

Most queries in L<DBIx::QuickORM> are synchronous: you call a fetch method on a
L<DBIx::QuickORM::Handle> and it blocks until the database returns. Sometimes
you want to fire a query off and keep working while the database does its job.
This guide covers the three ways to do that - C<async>, C<aside>, and
C<forked> - what each one means, when to reach for it, and the rules you must
follow.

All three are selected on a handle and are mutually exclusive; asking for more
than one at once is an error. See L<DBIx::QuickORM::Handle> for the handle API
and L<DBIx::QuickORM::Connection> for the connection that owns these queries.

=head1 THE THREE MODES

=head2 async - driver-level asynchronous

    my $h = $orm->handle('events', {processed => 0});
    my $iter = $h->async->iterator;    # query is sent, does not block

This uses the database driver's own asynchronous support. The query runs on
your B<primary> connection while your code keeps going. It is the cheapest
option - no extra connection, no extra process - but it has the strictest
constraints (see L</"RULES AND CONSTRAINTS"> below), because the one connection
is busy until the query finishes.

Not every database supports this. If the dialect does not advertise async
support (for example L<DBD::SQLite>), selecting C<async> and running a query
throws an exception. Use C<forked> instead on those backends.

=head2 aside - asynchronous on a separate connection

    my $iter = $h->aside->iterator;

An C<aside> query is the same driver-level async mechanism, but run on a
B<separate> connection obtained from the ORM rather than on your primary
connection. Because the primary connection stays free, an aside query does
B<not> block other work on it: you can run normal synchronous queries, open
transactions, and even start more aside or forked queries while it is in
flight.

Reach for C<aside> when you want async behavior but do not want to tie up your
main connection. It still requires a driver that supports async.

=head2 forked - run the query in a child process

    my $iter = $h->forked->iterator;

A C<forked> query C<fork()>s a child process with its own database connection,
runs the query there, and streams the results back to the parent. The parent
never blocks while the child works.

This is the way to get asynchronous behavior on databases whose driver has no
native async support, such as SQLite. Like C<aside>, it runs off your primary
connection, so it does not block it.

The results cross from child to parent over a pipe (via L<Atomic::Pipe>) with
C<zstd> compression, so more rows fit in the pipe buffer and less data hits the
wire. You do not interact with the transport directly - you just pull rows.

=head1 RUNNING AN ASYNC QUERY

The pattern is the same for all three modes. Pick the mode, get an
L<DBIx::QuickORM::Iterator>, poll C<ready()>, then drain the results:

    my $iter = $h->async->iterator;    # or ->aside->iterator / ->forked->iterator

    until ($iter->ready) {
        do_something_useful();          # the DB is working in the background
    }

    while (my $row = $iter->next) {
        ...                             # rows arrive here
    }

C<ready()> is non-blocking: it polls and returns true once results are
available (for a synchronous handle it is always true). C<next()> pulls one row
at a time; if results have not arrived yet it blocks until they do.

C<all()>, C<count()>, C<iterate()>, and C<first()>/C<one()> in C<data_only>
mode are B<not> available on an async handle - C<all()> in particular would
have to block, defeating the purpose. Use C<iterator()> and its C<ready()>
method instead.

=head2 Single-row async results

C<one()> and C<first()> on an async handle return a
L<DBIx::QuickORM::Row::Async> placeholder rather than a real row. It is a
transparent proxy: it is true while pending, and the first time you call a real
method on it (or check C<isa>/C<can>/C<DOES>) it materializes the row from the
arrived results and swaps itself out in place, so you transparently end up
holding the real row object. If the query returned no data or was cancelled the
proxy becomes invalid - it is false in boolean context and method calls croak.

    my $row = $h->async->one;    # placeholder, true while pending
    print $row->field('name');   # blocks if needed, then forwards to the real row

Inserts behave the same way: an C<insert> on an async handle returns a
placeholder row that materializes once the insert result arrives.

=head1 CANCELLATION

If you no longer need an in-flight query you can cancel it:

    $iter->cancel if $iter->can('cancel');

Whether an in-flight query can truly be cancelled depends on the mode and the
dialect. Driver-level C<async> queries can be cancelled only when the dialect
supports it; C<forked> queries can always be cancelled (the child process is
signalled and reaped). When a query cannot be cancelled, finalizing it waits
for it to finish instead.

You normally do not have to clean up by hand. When an async statement handle
goes out of scope it finalizes itself: cancelling the query if it can and the
result has not arrived, otherwise waiting for it, and then releasing the slot
it held on the connection. A single-row placeholder that is dropped before it
materializes is likewise abandoned cleanly.

=head1 RULES AND CONSTRAINTS

These rules keep the connection state consistent. Most apply to driver-level
C<async> specifically, because it shares your primary connection.

=over 4

=item One driver-async query at a time per connection.

Because an C<async> query occupies the primary connection, you must finish (or
cancel) it before running anything else on that connection. Starting a second
query while an async query is still in flight throws an exception telling you
the running query must be completed first. Drain the iterator, or call
C<cancel>, before issuing the next query.

=item No transactions while an async query is active.

You cannot open a transaction while a driver-async query is in flight on the
connection, and you cannot commit or roll one back either - attempting it
throws. Finish the async query first. See
L<DBIx::QuickORM::Manual::Transactions>.

=item C<aside> and C<forked> do not block the primary connection.

Because these run on a separate connection or a child process, they sidestep
the two rules above: you may keep using the primary connection - including
opening transactions and starting further aside/forked queries - while they run.

=item Connections are not shared across processes.

A connection belongs to the process that created it; you cannot use it across a
C<fork()> of your own. (The C<forked> mode handles its own child connection for
you - this is about your application forking.) See
L<DBIx::QuickORM::Manual::Connections>.

=back

=head1 WHICH ONE SHOULD I USE?

=over 4

=item Use C<async> when

your driver supports it and you have a single query you want to overlap with
other (non-database) work, and you are fine not touching the connection until
it finishes.

=item Use C<aside> when

your driver supports async but you want to keep using the primary connection -
including transactions and other queries - while the query runs.

=item Use C<forked> when

your driver has no native async support (for example SQLite), or you want full
isolation from the primary connection at the cost of a child process and the
pipe transport.

=back

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Handle>

The C<async>/C<aside>/C<forked> mode selectors and the fetch methods.

=item L<DBIx::QuickORM::Connection>

Owns the connection and tracks in-flight async, aside, and forked queries.

=item L<DBIx::QuickORM::Manual::Transactions>

Transactions, and why they cannot overlap a driver-async query.

=item L<DBIx::QuickORM::Manual>

The documentation hub.

=back

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
