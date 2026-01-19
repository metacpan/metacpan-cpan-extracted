package DBIx::Class::Async::ResultSet::Pager;

use strict;
use warnings;
use Future;
use POSIX qw(ceil);

=head1 NAME

DBIx::Class::Async::ResultSet::Pager - Asynchronous pagination handling for Async ResultSets

=head1 VERSION

Version 0.40

=cut

our $VERSION = '0.40';

=head1 SYNOPSIS

    my $rs = $schema->resultset('User')->page(1);
    my $pager = $rs->pager;

    # total_entries returns a Future
    $pager->total_entries->then(sub {
        my $total = shift;
        print "Total users: $total\n";
        print "Last page: " . $pager->last_page . "\n";
        return Future->done;
    })->get;

=head1 DESCRIPTION

This module provides a pagination object for L<DBIx::Class::Async::ResultSet>. It
is designed to work similarly to L<Data::Page>, but with the critical difference
that the total entry count is fetched asynchronously from the database worker.

=head1 CONSTRUCTOR

=head2 new

    my $pager = DBIx::Class::Async::ResultSet::Pager->new(
        resultset => $rs
    );

Instantiates a new pager. Usually called via C<< $rs->pager >>.

=cut

sub new {
    my ($class, %args) = @_;
    my $rs = $args{resultset};

    return bless {
        _rs            => $rs,
        _total_entries => undef,
        _rows          => $rs->{_attrs}->{rows} // 10,
        _page          => $rs->{_attrs}->{page} // 1,
    }, $class;
}

=head1 METHODS

=head2 total_entries

Returns a L<Future> that resolves to the total number of entries matching the
ResultSet condition, ignoring pagination limits. The result is cached after
the first call.

=cut

sub total_entries {
    my $self = shift;

    if (defined $self->{_total_entries}) {
        return Future->done($self->{_total_entries});
    }

    return $self->{_rs}->count_total->then(sub {
        my $val = shift;
        my $count = ref($val) eq 'ARRAY' ? $val->[0] : $val;

        $self->{_total_entries} = $count // 0;
        return Future->done($self->{_total_entries});
    });
}

=head2 entries_per_page

Returns the number of entries per page (C<rows> attribute).

=cut

sub entries_per_page { shift->{_rows} }

=head2 current_page

Returns the current page number.

=cut

sub current_page     { shift->{_page} }

=head2 last_page

Returns the total number of pages. Note: This assumes C<total_entries> has
been resolved. If not, it defaults to 1.

=cut

sub last_page {
    my $self = shift;
    my $total = $self->{_total_entries} // 0;
    return 1 if $total == 0;
    return ceil($total / $self->{_rows});
}

=head2 entries_on_this_page

Returns the number of entries on the current page.

=cut

sub entries_on_this_page {
    my $self = shift;
    my $total = $self->{_total_entries} // 0;
    return 0 if $total == 0;

    my $last = $self->last_page;
    return 0 if $self->{_page} > $last;

    if ($self->{_page} < $last) {
        return $self->{_rows};
    } else {
        return $total % $self->{_rows} || $self->{_rows};
    }
}

=head2 previous_page

Returns the previous page number or C<undef> if on the first page.

=cut

sub previous_page {
    my $self = shift;
    return ($self->{_page} > 1) ? $self->{_page} - 1 : undef;
}

=head2 next_page

Returns the next page number or C<undef> if on the last page.

=cut

sub next_page {
    my $self = shift;
    my $total = $self->{_total_entries} // 0;
    return ($self->{_page} < $self->last_page) ? $self->{_page} + 1 : undef;
}

=head2 next_page_rs

Returns a new L<DBIx::Class::Async::ResultSet> for the next page, or C<undef>.

=cut

sub next_page_rs {
    my $self = shift;
    my $next = $self->next_page or return undef;
    return $self->{_rs}->page($next);
}

=head2 previous_page_rs

Returns a new L<DBIx::Class::Async::ResultSet> for the previous page, or C<undef>.

=cut

sub previous_page_rs {
    my $self = shift;
    my $prev = $self->previous_page or return undef;
    return $self->{_rs}->page($prev);
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

    perldoc DBIx::Class::Async::ResultSet::Pager

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

1; # End of DBIx::Class::Async::ResultSet::Pager
