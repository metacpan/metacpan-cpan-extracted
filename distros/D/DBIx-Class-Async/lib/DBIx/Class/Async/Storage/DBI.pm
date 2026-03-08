package DBIx::Class::Async::Storage::DBI;

$DBIx::Class::Async::Storage::DBI::VERSION   = '0.64';
$DBIx::Class::Async::Storage::DBI::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;
use base 'DBIx::Class::Async::Storage';
use DBIx::Class::Async::Storage::DBI::Cursor;

=head1 NAME

DBIx::Class::Async::Storage::DBI - DBI-based async storage backend for DBIx::Class::Async

=head1 VERSION

Version 0.64

=head1 SYNOPSIS

    # Typically obtained via the storage of an async schema
    my $storage = $schema->storage;

    # Enable SQL debugging
    $storage->debug(1);

    # Or use a custom debug object
    my $stats = DBIx::Class::Storage::Statistics->new;
    $storage->debugobj($stats);
    $storage->debug(1);

    # Or send debug output to a specific filehandle
    open my $log_fh, '>>', 'sql.log';
    $storage->debugfh($log_fh);
    $storage->debug(1);

    # Async Cursor / Streaming Support

    my $rs = $schema->resultset('User')->search({ active => 1 });

    # Create an async cursor to iterate over results without blocking the loop
    my $cursor = $storage->cursor($rs);

    # Iterate through the results one by one
    my $next_item;
    $next_item = sub {
        $cursor->next->then(sub {
            my $row_data = shift;
            return Future->done unless $row_data; # End of stream

            say "Processing user data: " . $row_data->{name};

            # Recurse to get the next item
            return $next_item->();
        });
    };

    $next_item->()->get;

    # Low-Level Execution

    # Execute raw SQL through the worker pool
    $storage->execute_all("UPDATE users SET last_login = ?", [ time ])
            ->then(sub {
                say "Bulk update complete.";
            });

    # Modern Async/Await iteration (Recommended)
    use Future::AsyncAwait;

    my $cursor = $schema->storage->cursor($rs);

    async sub process_all_users {
        while (my $row = await $cursor->next) {
            say "Streaming user: " . $row->name;
        }
        say "All users processed.";
    }

=head1 DESCRIPTION

This class provides a DBI-based storage backend for L<DBIx::Class::Async::Schema>.
It extends L<DBIx::Class::Async::Storage> and implements DBI-specific functionality
for managing database connections and operations in an asynchronous worker pool
environment.

Unlike traditional L<DBIx::Class::Storage::DBI>, this storage class does not
maintain database handles in the parent process. Instead, database handles are
managed by worker processes, allowing for non-blocking asynchronous database
operations using L<Future> objects.

This class is automatically instantiated when you connect to a database using
L<DBIx::Class::Async::Schema/connect> and generally does not need to be
instantiated directly.

=head1 METHODS

=head2 dbh

  my $dbh = $storage->dbh;

Returns C<undef> in async storage mode.

Unlike traditional L<DBIx::Class::Storage::DBI>, the async storage layer does
not maintain a database handle in the parent process. Instead, database handles
are held by worker processes in the background worker pool, which execute
queries asynchronously.

This method exists for API compatibility with standard L<DBIx::Class> storage
objects, but always returns C<undef> to indicate that direct database handle
access is not available in async mode.

  my $storage = $schema->storage;
  my $dbh = $storage->dbh;  # Always undef in async mode

  if (!defined $dbh) {
      say "Running in async mode - no direct DBH access";
  }

If you need to perform database operations, use the L<DBIx::Class::Async::ResultSet>
and L<DBIx::Class::Async::Row> methods which handle async execution transparently
through the worker pool.

=cut

sub dbh {
    my $self = shift;
    # In Async mode, the parent process doesn't hold a DBH.
    # The workers hold the DBHs.
    return undef;
}

=head2 cursor

  my $cursor = $storage->cursor($resultset);

Creates and returns a L<DBIx::Class::Async::Storage::DBI::Cursor> object
for asynchronously iterating through a ResultSet's rows.

The cursor provides a low-level interface for fetching rows one at a time
using Futures, which is useful for processing large result sets without
loading all rows into memory at once.

B<Arguments>

=over 4

=item * C<$resultset> - A L<DBIx::Class::Async::ResultSet> object

=back

B<Returns>

A L<DBIx::Class::Async::Storage::DBI::Cursor> object configured for the
given ResultSet.

  use Future::AsyncAwait;

  my $rs = $schema->resultset('User');
  my $cursor = $storage->cursor($rs);

  my $iter = async sub {
      while (my $row = await $cursor->next) {
          say $row->name;
      }
  };

  $iter->get;

The cursor respects the ResultSet's C<rows> attribute for batch fetching:

  my $rs = $schema->resultset('User')->search(undef, { rows => 50 });
  my $cursor = $storage->cursor($rs);  # Fetches 50 rows at a time

See L<DBIx::Class::Async::Storage::DBI::Cursor> for available cursor methods.

=cut

sub cursor {
    my ($self, $rs) = @_;

    # Just like DBIC, we return a DBI-specific cursor
    return DBIx::Class::Async::Storage::DBI::Cursor->new(
        storage => $self,
        rs      => $rs,
    );
}

=head2 debug

  # Get current debug level
  my $level = $storage->debug;

  # Set debug level
  $storage->debug(1);

Gets or sets the debug level for the storage layer.

When called without arguments, returns the current debug level (defaults to 0).
When called with an argument, sets the debug level to the specified value and
returns it.

B<Arguments>

=over 4

=item * C<$level> (optional) - Integer debug level (0 = off, higher values = more verbose)

=back

B<Returns>

The current or newly set debug level.

  # Enable debugging
  $storage->debug(1);

  # Check if debugging is enabled
  if ($storage->debug) {
      say "Debug mode is on at level " . $storage->debug;
  }

  # Disable debugging
  $storage->debug(0);

When debugging is enabled, SQL statements will be sent to the L</debugobj>
for output. By default, this prints to C<STDERR>, but you can customise the
output destination using L</debugobj> or L</debugfh>.

=cut

sub debug {
    my ($self, $level) = @_;
    return $self->{debug} = $level if defined $level;
    return $self->{debug} || 0;
}

=head2 debugobj

  # Get current debug object
  my $obj = $storage->debugobj;

  # Set a custom debug object
  $storage->debugobj($custom_debug_object);

Gets or sets the debug object used for SQL statement logging.

When called without arguments, returns the current debug object. If no debug
object has been set, creates and returns a default L<DBIx::Class::Storage::Statistics>
object.

When called with an argument, sets the debug object to the provided value.
The debug object must implement a C<print> method that will be called with
SQL statements and bind values when L</debug> is enabled.

B<Arguments>

=over 4

=item * C<$debug_object> (optional) - An object implementing a C<print> method

=back

B<Returns>

The current or newly set debug object.

  # Use default debug object (prints to STDERR)
  my $stats = $storage->debugobj;
  $storage->debug(1);

  # Use a custom debug object
  package MyDebugger;
  sub new { bless {}, shift }
  sub print { my ($self, $msg) = @_; warn "SQL: $msg" }

  package main;
  $storage->debugobj(MyDebugger->new);
  $storage->debug(1);

This method provides API compatibility with L<DBIx::Class::Storage::DBI>.

=cut

sub debugobj {
    my $self = shift;

    if (@_) {
        $self->{debugobj} = shift;
        return $self;
    }

    return $self->{debugobj} ||= do {
        require DBIx::Class::Storage::Statistics;
        DBIx::Class::Storage::Statistics->new;
    };
}

=head2 debugfh

  # Get current debug filehandle
  my $fh = $storage->debugfh;

  # Set debug output to a filehandle
  $storage->debugfh(\*STDERR);

  # Log to a file
  open my $log_fh, '>>', 'sql.log';
  $storage->debugfh($log_fh);

Gets or sets the filehandle used for debug output.

This is a convenience method that creates a L<DBIx::Class::Storage::Statistics>
object configured to print to the specified filehandle, and sets it as the
L</debugobj>.

B<Arguments>

=over 4

=item * C<$filehandle> (optional) - A filehandle glob or reference

=back

B<Returns>

When called without arguments, returns the filehandle from the current L</debugobj>
if available, or C<undef> if no debug object is set.

When called with an argument, sets the debug filehandle and returns C<$self>
for method chaining.

  # Send debug output to a log file
  open my $log, '>>', 'queries.log' or die $!;
  $storage->debugfh($log);
  $storage->debug(1);

  # Send to STDOUT instead of STDERR
  $storage->debugfh(\*STDOUT);

This method provides API compatibility with L<DBIx::Class::Storage::DBI>.

=cut

sub debugfh {
    my $self = shift;

    if (@_) {
        my $fh = shift;
        require DBIx::Class::Storage::Statistics;
        my $stats = DBIx::Class::Storage::Statistics->new;
        $stats->debugfh($fh);
        $self->debugobj($stats);
        return $self;
    }

    return $self->debugobj->debugfh if $self->{debugobj};
    return undef;
}

=head1 ARCHITECTURE

This storage class implements a distributed, non-blocking execution model that
differs fundamentally from traditional L<DBIx::Class::Storage::DBI>:

=over 4

=item B<No Parent Process DBH>

The parent process never instantiates a L<DBI> handle. All database connections
are isolated within worker processes. This prevents the B<"forked handle">
corruption common in multiprocess Perl applications and keeps the main event
loop lightweight.

=item B<Async Operations>

Every database interaction (search, create, update, etc.) returns an
L<IO::Async::Future> object. This allows the main application to continue
processing web requests, timers, or other I/O while waiting for the worker
to return results.

=item B<Worker Pool via IO::Async::Function>

Queries are dispatched to a persistent pool of background workers. By using
persistent workers with B<state-cached connections>, the bridge eliminates
the latency of C<connect/disconnect> cycles for every query.

=item B<Transparent API>

The bridge provides a high degree of parity with the standard DBIC API.
Advanced features like C<prefetch>, C<collapse>, and complex transactions
(C<txn_do>) are supported through a specialised serialisation layer that
reconstructs object graphs across process boundaries.

=back

=head1 DEBUGGING

L<DBIx::Class::Async::Storage::DBI> provides debugging capabilities compatible
with standard L<DBIx::Class::Storage::DBI>:

  # Enable basic debugging (output to STDERR)
  $storage->debug(1);

  # Customise debug output
  open my $log, '>>', 'sql.log';
  $storage->debugfh($log);
  $storage->debug(1);

  # Use a custom debug object
  my $custom_debugger = MyDebugger->new;
  $storage->debugobj($custom_debugger);
  $storage->debug(1);

When debugging is enabled, SQL statements generated by the storage layer
will be sent to the debug object's C<print> method. This allows you to
inspect the actual SQL being executed by your async queries.

B<Note>: Debug output occurs in the parent process before queries are sent
to workers, so you'll see the SQL as it's generated, not necessarily in
the exact order it's executed by the worker pool.

=cut

=head1 CAVEATS

=head2 Transaction Management

Transactions in L<DBIx::Class::Async> differ from standard L<DBIx::Class>
because the I/O is delegated to a worker pool. You cannot use the
traditional C<< $schema->storage->txn_begin >> pattern in a non-blocking
loop, as subsequent calls might be routed to different workers.

=head3 The Recommended Approach: C<txn_do>

To ensure atomicity, use the C<txn_do> or C<txn_batch> methods. These
methods bundle multiple operations into a single "Instruction Set" that
is dispatched to a B<single worker process>.

The worker executes the entire block within a local database transaction.
If any step fails, the worker performs a local C<rollback> and returns
the error to the parent process.

=head3 Placeholder Resolution

The async C<txn_do> supports internal variable registration. You can
create a record in Step A and use its auto-incremented ID in Step B
using the C<$name.id> syntax. This allows for complex, multi-step
dependent operations to remain fully asynchronous and atomic.

=head2 ResultSet State

Because data is deflated for transport between the worker and the parent,
the objects returned by C<on_done> are "POPO" (Plain Old Perl Objects/HashRefs)
rather than "Live" L<DBIx::Class::Row> objects. Calling methods like
C<update> or C<delete> on these returned objects will not affect the
database directly.

=cut

=head1 SEE ALSO

=over 4

=item * L<DBIx::Class::Async::Storage> - Base async storage class

=item * L<DBIx::Class::Async::Storage::DBI::Cursor> - Async cursor implementation

=item * L<DBIx::Class::Async::Schema> - Async schema class

=item * L<DBIx::Class::Async::ResultSet> - Async ResultSet class

=item * L<DBIx::Class::Storage::DBI> - Traditional synchronous DBI storage

=item * L<DBIx::Class::Storage::Statistics> - Debug object for SQL logging

=item * L<Future> - Asynchronous result objects

=item * L<IO::Async> - Asynchronous event-driven programming

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/DBIx-Class-Async>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/DBIx-Class-Async/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Async::Storage::DBI

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/DBIx-Class-Async/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Async>

=item * Search MetaCPAN

L<https://metacpan.org/dist/DBIx-Class-Async/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of DBIx::Class::Async::Storage::DBI
