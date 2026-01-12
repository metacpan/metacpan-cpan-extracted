package DBIx::Class::Async::Storage;

use strict;
use warnings;

=head1 NAME

DBIx::Class::Async::Storage - Storage Layer for DBIx::Class::Async

=head1 VERSION

Version 0.25

=cut

our $VERSION = '0.25';

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
    return bless \%args, $class;
}

=head1 METHODS

=head2 schema

    my $schema = $storage->schema;

Returns the associated schema object.

=over 4

=item B<Returns>

The L<DBIx::Class::Async::Schema> instance associated with this storage.

=back

=cut

sub schema {
    my $self = shift;
    return $self->{_schema};
}

=head2 dbh

    my $dbh = $storage->dbh;

Returns the database handle.

=over 4

=item B<Returns>

Always returns C<undef> since C<DBIx::Class::Async> does not provide direct
database handle access in the asynchronous architecture.

=item B<Notes>

This method exists for compatibility with L<DBIx::Class> but returns C<undef>
because database operations are handled by a separate worker process.

=back

=cut

sub dbh {
    my $self = shift;
    # Return undef since we don't have direct DB handle access
    return undef;
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
    $self->{_schema}->disconnect if $self->{_schema};
    return 1;
}

=head2 debug

    $storage->debug(1);
    my $level = $storage->debug;

Gets or sets the debug level.

=over 4

=item B<Parameters>

=over 8

=item C<$level>

Optional debug level to set.

=back

=item B<Returns>

The current debug level (defaults to 0).

=item B<Notes>

This is a no-op method provided for compatibility. Debugging in asynchronous
contexts is typically handled differently.

=back

=cut

sub debug {
    my ($self, $level) = @_;
    # No-op for compatibility
    return $level || 0;
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
