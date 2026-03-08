package DBIx::Class::Async::Storage;

$DBIx::Class::Async::Storage::VERSION   = '0.64';
$DBIx::Class::Async::Storage::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;
use Scalar::Util qw(weaken);

=head1 NAME

DBIx::Class::Async::Storage - Storage Layer for DBIx::Class::Async

=head1 VERSION

Version 0.64

=cut

=head1 SYNOPSIS

    use DBIx::Class::Async::Storage;

    # Typically instantiated automatically via DBIx::Class::Async::Schema
    my $storage = $schema->storage;

    # Connection Management

    # Check if the worker pool is currently connected
    if ( $storage->connected ) {
        say "Worker pool is active and ready.";
    }

    # Gracefully shut down all background worker processes and disconnect
    $storage->disconnect;

    # Metadata & Configuration

    # Access the underlying schema instance
    my $schema = $storage->schema;

    # Inspect the DSN (Data Source Name) currently in use
    my $dsn = $storage->connect_info->[0];

    # Debugging

    # Storage acts as the gateway for the debug environment
    $storage->debug(1) if $ENV{DBIC_TRACE};

=head1 DESCRIPTION

C<DBIx::Class::Async::Storage> is the orchestration layer for the asynchronous
bridge. Unlike standard L<DBIx::Class::Storage::DBI>, this class does not
connect to the database directly. Instead, it manages the life-cycle of a
background worker pool.

=head1 CONSTRUCTOR

=head2 new

    my $storage = DBIx::Class::Async::Storage->new(
        schema   => $schema,
        async_db => $bridge_engine,
    );

B<async_db> is the internal engine (the 'bridge') that handles
communication with the worker processes.

This constructor automatically weakens the reference to the parent L<schema>
to prevent circular reference leaks, ensuring that worker processes are
correctly reaped when the schema object goes out of scope.

=cut

sub new {
    my ($class, %args) = @_;

    # Standard DBIC storage expects a reference to the schema
    my $self = bless {
        _schema   => $args{schema},
        _async_db => $args{async_db}, # The worker pool engine
    }, $class;

    # WEAKEN the schema reference to prevent circular memory leaks
    # that caused your "5 vs 2 processes" test failure.
    weaken($self->{_schema}) if $self->{_schema};

    return $self;
}

=head1 METHODS

=head2 cursor

  my $cursor = $storage->cursor($resultset);

Creates and returns a cursor object for iterating through a ResultSet's rows.

This is an abstract method that must be implemented by storage subclasses
(such as L<DBIx::Class::Async::Storage::DBI>). Calling this method directly
on the base storage class will throw an error.

B<Arguments>

=over 4

=item * C<$resultset> - A L<DBIx::Class::Async::ResultSet> object

=back

B<Returns>

A cursor object appropriate for the storage type. For DBI-based storage,
this returns a L<DBIx::Class::Async::Storage::DBI::Cursor> object.

  # Don't call on base class directly
  my $cursor = $storage->cursor($rs);  # Dies!

  # Use through a DBI storage subclass
  my $dbi_storage = DBIx::Class::Async::Storage::DBI->new(...);
  my $cursor = $dbi_storage->cursor($rs);  # Works!

Subclasses should override this method to return storage-specific cursor
implementations.

=cut

sub cursor {
    my $self = shift;
    die "Method 'cursor' must be implemented by a subclass of " . ref($self);
}

=head2 dbh

    my $dbh = $storage->dbh; # Returns undef

In this architecture, the Parent process B<must not> touch the database. This
method always returns C<undef>. Any code relying on C<$schema-E<gt>storage-E<gt>dbh>
will fail, which is intentional to prevent accidental blocking I/O in the
main event loop.

=cut

sub dbh {
    my $self = shift;
    # In Async mode, the parent process doesn't hold a DBH.
    return undef;
}

=head2 schema

  my $schema = $storage->schema;

Returns the L<DBIx::Class::Async::Schema> object that this storage layer
is associated with.

This provides a back-reference from the storage to its parent schema,
allowing storage components to access schema-level information and other
ResultSources when needed.

Note: The schema reference is weakened internally to prevent circular
reference memory leaks between the schema and storage objects.

  my $storage = $schema->storage;
  my $parent_schema = $storage->schema;

  # Access schema configuration
  my $source = $parent_schema->source('User');

=cut

sub schema {
    my $self = shift;
    return $self->{_schema};
}

=head2 disconnect

    $storage->disconnect;

Signals the background worker pool to shut down. This is an asynchronous-safe
cleanup:

1. It stops the worker processes.

2. It closes IPC pipes or sockets used by the bridge.

3. It clears the local query cache.

=cut

sub disconnect {
    my $self = shift;

    # Delegate cleanup to the functional library
    if ($self->{_async_db}) {
        DBIx::Class::Async::disconnect($self->{_async_db});
    }

    return 1;
}

=head1 INTERNAL NOTES

This class implements a specialised B<"Proxy Storage"> layer for the L<DBIx::Class::Async>
ecosystem. Unlike standard DBIC storage, this layer does not hold a local
database connection. Instead, it acts as a B<Command Dispatcher>.

B<Key Architectural Differences>:

=over 4

=item * Proxied Execution

SQL generation and execution occur within persistent background workers
via L<IO::Async::Function>.

=item * Asynchronous Transactions

Transactional integrity is maintained by routing related commands (C<txn_do>,
C<txn_batch>) to a single dedicated worker to ensure atomicity.

=item * Distributed State

Database handle management is isolated to the worker process, utilising

B<InactiveDestroy> to prevent handle leakage or cross-process corruption.

=item * Compatibility Shim

It provides enough of the L<DBIx::Class::Storage> API to allow standard
ResultSets to function while redirecting all I/O to the L<IO::Async> event
loop.

=back

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::Async> - Asynchronous DBIx::Class interface

=item *

L<DBIx::Class::Async::Schema> - Asynchronous schema class

=item *

L<DBIx::Class::Storage> - Standard DBIx::Class storage interface

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

    perldoc DBIx::Class::Async::Storage

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

1; # End of DBIx::Class::Async::Storage
