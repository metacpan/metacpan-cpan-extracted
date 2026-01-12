package DBIx::Class::Async::Cursor;

use strict;
use warnings;
use Future;

=head1 NAME

DBIx::Class::Async::Cursor - Asynchronous resultset cursor

=head1 VERSION

Version 0.25

=cut

our $VERSION = '0.25';

=head1 SYNOPSIS

  my $cursor = $schema->resultset('User')->search({ active => 1 })->cursor;

  while (my $user = await $cursor->next) {
      print "Processing " . $user->username . "\n";
  }

=head1 DESCRIPTION

This class provides a way to fetch results from a L<DBIx::Class::Async::ResultSet>
one by one. It mimics the behaviour of standard L<DBIx::Class::Cursor> but
operates in an asynchronous manner using L<Future>.

To improve performance, it internally fetches rows in batches (default: 20)
but yields them individually.

=head1 METHODS

=head2 new

Internal constructor used by L<DBIx::Class::Async::ResultSet>.

=cut

sub new {
    my ($class, %args) = @_;
    return bless {
        rs       => $args{rs},
        buffer   => [],
        page     => 1,
        finished => 0,
        batch    => $args{batch} || 20,
    }, $class;
}

=head2 next

  my $row_future = $cursor->next;
  my $row = await $row_future;

Returns a L<Future> that resolves to the next L<DBIx::Class::Async::Row>
object in the resultset, or C<undef> if no more rows are available.

=cut

sub next {
    my ($self) = @_;

    # Return from internal buffer if we have rows ready
    if (@{$self->{buffer}}) {
        return Future->done(shift @{$self->{buffer}});
    }

    # Stop if the resultset is exhausted
    return Future->done(undef) if $self->{finished};

    # Fetch the next page of results
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
        $self->{buffer} = $rows;
        return Future->done(shift @{$self->{buffer}});
    });
}

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

    perldoc DBIx::Class::Async::Cursor

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

1; # End of DBIx::Class::Async::Cursor
