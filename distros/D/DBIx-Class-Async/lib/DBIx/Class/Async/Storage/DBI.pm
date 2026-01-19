package DBIx::Class::Async::Storage::DBI;

use strict;
use warnings;
use base 'DBIx::Class::Async::Storage';
use DBIx::Class::Async::Storage::DBI::Cursor;

=head1 NAME

DBIx::Class::Async::Storage::DBI - DBI-based async storage backend for DBIx::Class::Async

=head1 VERSION

Version 0.40

=cut

our $VERSION = '0.40';

=head1 SYNOPSIS

  use DBIx::Class::Async::Schema;

  my $schema = DBIx::Class::Async::Schema->connect(
      "dbi:SQLite:dbname=mydb.db",
      undef,
      undef,
      { sqlite_unicode => 1 },
      { workers => 4, schema_class => 'MyApp::Schema' }
  );

  my $storage = $schema->storage;
  # $storage is a DBIx::Class::Async::Storage::DBI instance

  # Create a cursor for async iteration
  my $rs = $schema->resultset('User');
  my $cursor = $storage->cursor($rs);

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

Note: The actual debug output behavior may vary depending on the storage
implementation and connected database driver.

=cut

sub debug {
    my ($self, $level) = @_;
    return $self->{debug} = $level if defined $level;
    return $self->{debug} || 0;
}

=head1 ARCHITECTURE

This storage class operates differently from traditional L<DBIx::Class::Storage::DBI>:

=over 4

=item * B<No Parent Process DBH>

The parent process does not hold database handles. All database connections
are managed by worker processes.

=item * B<Async Operations>

All database operations return L<Future> objects, enabling non-blocking
asynchronous execution.

=item * B<Worker Pool>

Database queries are distributed across a pool of worker processes, allowing
for parallel execution and improved throughput.

=item * B<Transparent API>

Despite the async architecture, the API remains similar to standard L<DBIx::Class>,
making migration easier.

=back

=head1 SEE ALSO

=over 4

=item * L<DBIx::Class::Async::Storage> - Base async storage class

=item * L<DBIx::Class::Async::Storage::DBI::Cursor> - Async cursor implementation

=item * L<DBIx::Class::Async::Schema> - Async schema class

=item * L<DBIx::Class::Async::ResultSet> - Async ResultSet class

=item * L<DBIx::Class::Storage::DBI> - Traditional synchronous DBI storage

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
