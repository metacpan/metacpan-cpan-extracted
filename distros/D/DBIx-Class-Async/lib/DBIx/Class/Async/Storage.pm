package DBIx::Class::Async::Storage;

use strict;
use warnings;
use Scalar::Util qw(weaken);

=head1 NAME

DBIx::Class::Async::Storage - Storage Layer for DBIx::Class::Async

=head1 VERSION

Version 0.27

=cut

our $VERSION = '0.27';

=head1 SYNOPSIS

    use DBIx::Class::Async::Storage;

    # Typically created internally by DBIx::Class::Async::Schema
    my $storage = DBIx::Class::Async::Storage->new(
        _schema => $schema_instance,
    );

    # Get the schema
    my $schema = $storage->schema;

    # Disconnect
    $storage->disconnect;

=head1 DESCRIPTION

C<DBIx::Class::Async::Storage> provides a minimal storage layer implementation
for L<DBIx::Class::Async>. This class exists primarily for compatibility with
the L<DBIx::Class> ecosystem, providing the expected storage interface without
direct database handle management.

In the asynchronous architecture, database operations are delegated to a
separate worker process or service, so this storage layer does not manage
traditional database connections.

=head1 CONSTRUCTOR

=head2 new

    my $storage = DBIx::Class::Async::Storage->new(
        _schema => $schema,  # DBIx::Class::Async::Schema instance
    );

Creates a new storage object.

=over 4

=item B<Parameters>

=over 8

=item C<_schema>

A L<DBIx::Class::Async::Schema> instance. This is typically passed internally.

=back

=item B<Returns>

A new C<DBIx::Class::Async::Storage> object.

=back

=cut

sub new {
    my ($class, %args) = @_;

    # Standard DBIC storage expects a reference to the schema
    my $self = bless {
        _schema  => $args{schema},
        async_db => $args{async_db}, # The worker pool engine
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

  my $dbh = $storage->dbh;

Returns C<undef> in async storage mode.

Unlike traditional L<DBIx::Class::Storage>, the async storage layer does not
maintain a database handle in the parent process. Instead, database handles
are held by worker processes in the background worker pool, which execute
queries asynchronously.

This method exists for API compatibility with standard DBIx::Class storage
objects, but always returns C<undef> to indicate that direct database handle
access is not available in async mode.

  my $storage = $schema->storage;
  my $dbh = $storage->dbh;  # Always undef in async mode

  if (!defined $dbh) {
      say "Running in async mode - no direct DBH access";
  }

If you need to perform database operations, use the ResultSet and Row
methods which handle async execution transparently through the worker pool.

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

Disconnects from the database.

=over 4

=item B<Returns>

True (1) on success.

=item B<Notes>

This method calls C<disconnect> on the associated schema object if it exists.

=back

=cut

sub disconnect {
    my $self = shift;
    # Delegate cleanup to the async engine
    if ($self->{async_db} && $self->{async_db}->can('disconnect')) {
        $self->{async_db}->disconnect;
    }
    return 1;
}

=head1 INTERNAL NOTES

This class implements a minimal subset of the L<DBIx::Class::Storage> interface
required for compatibility with the L<DBIx::Class> ecosystem. Key differences:

=over 4

=item *

No direct database handle management

=item *

No SQL generation or execution

=item *

No transaction management at this level

=item *

Debug methods are no-ops or return mock objects

=back

Database operations in C<DBIx::Class::Async> are performed by a separate worker
process or service, so this storage layer acts primarily as a compatibility
shim.

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
