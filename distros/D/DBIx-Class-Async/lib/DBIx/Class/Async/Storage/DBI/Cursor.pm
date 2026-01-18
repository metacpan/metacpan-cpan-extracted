package DBIx::Class::Async::Storage::DBI::Cursor;

use strict;
use warnings;
use Future;

=head1 NAME

DBIx::Class::Async::Storage::DBI::Cursor - Asynchronous cursor for DBIx::Class ResultSets using Futures

=head1 VERSION

Version 0.35

=cut

our $VERSION = '0.35';

=head1 SYNOPSIS

  my $cursor = DBIx::Class::Async::Storage::DBI::Cursor->new(
      storage => $storage,
      rs      => $resultset,
  );

  $cursor->next->then(sub {
      my ($row) = @_;
      return unless $row;
      say $row->id;
  });

  # Reset and iterate again
  $cursor->reset;

=head1 DESCRIPTION

This module implements an asynchronous cursor abstraction for
L<DBIx::Class> ResultSets backed by DBI storage.

It fetches rows from a ResultSet incrementally in fixed-size batches
(pages) and exposes a C<next> method that returns a L<Future>.
Each call to C<next> resolves to a single row object or C<undef>
when the result set has been exhausted.

The cursor maintains an internal buffer and transparently issues
paginated queries using the ResultSet's C<page> and C<rows>
attributes.

This class is primarily intended for use by asynchronous storage
layers or consumers that wish to process large result sets without
loading all rows into memory at once.

=cut

=head1 CONSTRUCTOR

=head2 new

  my $cursor = DBIx::Class::Async::Storage::DBI::Cursor->new(%args);

Creates a new asynchronous cursor.

B<Arguments>

=over 4

=item * C<storage>

The storage object associated with the ResultSet.
This value is currently stored but not actively used by the cursor.

=item * C<rs>

A L<DBIx::Class::ResultSet> to iterate over.
If the ResultSet has a C<rows> attribute set, it will be used
as the batch size for pagination.

=back

B<Batch Size>

The cursor fetches rows in batches. The batch size is determined as follows:

=over 4

=item * If the ResultSet has C<< $rs->{_attrs}{rows} >> defined, that value is used

=item * Otherwise, a default batch size of 20 rows is used

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $rs         = $args{rs};
    my $batch_size = 20;         # default

    # Try to get rows attribute from ResultSet
    if ($rs && $rs->{_attrs} && defined $rs->{_attrs}{rows}) {
        $batch_size = $rs->{_attrs}{rows};
    }

    return bless {
        storage  => $args{storage},
        rs       => $rs,
        buffer   => [],
        page     => 1,
        finished => 0,
        batch    => $batch_size,
    }, $class;
}

=head1 METHODS

=head2 reset

  $cursor->reset;

Resets the cursor to the beginning of the ResultSet.

This clears the internal buffer, resets the page counter to 1,
and marks the cursor as not finished.

The cursor may then be iterated again from the start.

Returns the cursor itself.

B<INTERNAL STATE>

The cursor maintains the following internal state:

=over 4

=item * C<buffer>

An array reference holding prefetched rows.

=item * C<page>

The current page number used for pagination.

=item * C<finished>

Boolean flag indicating whether the result set has been exhausted.

=item * C<batch>

The number of rows fetched per page.

=back

These attributes are considered internal implementation details
and are not part of the public API.

=cut

sub reset {
    my ($self) = @_;

    $self->{buffer}   = [];
    $self->{page}     = 1;
    $self->{finished} = 0;

    return $self;
}

=head2 next

  my $future = $cursor->next;

Returns a L<Future> that resolves to the next row in the ResultSet.

B<Behaviour>

=over 4

=item * If buffered rows are available, the Future resolves immediately

=item * If the buffer is empty, the next page of rows is fetched asynchronously

=item * If no more rows are available, the Future resolves to C<undef>

=back

Each resolved value is a single row object (typically a
L<DBIx::Class::Row>), or C<undef> when iteration is complete.

This method never throws synchronously; all results are delivered
via the returned Future.

=cut

sub next {
    my ($self) = @_;

    # 1. Return from buffer if available
    if (@{$self->{buffer}}) {
        return Future->done(shift @{$self->{buffer}});
    }

    # 2. Stop if exhausted
    return Future->done(undef) if $self->{finished};

    # 3. Fetch next chunk
    return $self->{rs}->search(undef, {
        page => $self->{page},
        rows => $self->{batch}
    })->all->then(sub {
        my ($rows) = @_;

        if (!@$rows) {
            $self->{finished} = 1;
            return Future->done(undef);
        }

        $self->{page}++;
        $self->{buffer} = [ @$rows ];
        return Future->done(shift @{$self->{buffer}});
    });
}

=head1 LIMITATIONS

=over 4

=item * Requires a ResultSet that supports paging via C<page> and C<rows>

=item * Assumes that C<< $rs->search(...)->all >> returns a L<Future>

=item * Not thread-safe

=back

=head1 SEE ALSO

=over 4

=item * L<DBIx::Class::Async>

=item * L<DBIx::Class::Async::Storage>

=item * L<DBIx::Class::Async::Storage::DBI>

=item * L<Future>

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

    perldoc DBIx::Class::Async::Storage::DBI::Cursor

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

1; # End of DBIx::Class::Async::Storage::DBI::Cursor
