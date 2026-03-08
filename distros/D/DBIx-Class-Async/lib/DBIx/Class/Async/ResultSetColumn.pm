package DBIx::Class::Async::ResultSetColumn;

$DBIx::Class::Async::ResultSetColumn::VERSION   = '0.64';
$DBIx::Class::Async::ResultSetColumn::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

=head1 NAME

DBIx::Class::Async::ResultSetColumn - Asynchronous operations on a single ResultSource column

=head1 VERSION

Version 0.64

=head1 SYNOPSIS

    my $rs = $schema->resultset('Invoice')->search({ status => 'unpaid' });
    my $col = $rs->get_column('amount');

    # All methods return a Future
    $col->sum->then(sub {
        my $total = shift;
        say "Total unpaid: $total";
    });

    $col->max->on_done(sub {
        my $highest = shift;
        say "Highest unpaid invoice: $highest";
    });

=head1 DESCRIPTION

A C<ResultSetColumn> object represents a specific column within a L<DBIx::Class::Async::ResultSet>.
It is used to perform aggregate operations (like summation or averaging) or to fetch
single-column data sets asynchronously.

This object is typically obtained by calling C<get_column> on a
L<DBIx::Class::Async::ResultSet> object.

=head1 METHODS

=head2 sum

Returns a L<Future> resolving to the sum of all values in the column.

=head2 max / min

Returns a L<Future> resolving to the maximum or minimum value in the column,
respectively.

=head2 avg / average

Returns a L<Future> resolving to the average (mean) value of the column.

=head2 count

Returns a L<Future> resolving to the count of values in the column.

=head1 INTERNAL METHODS

=head2 new

Instantiates a new column proxy. Requires C<resultset>, C<column>, and C<async_db>.

=head2 _aggregate

The core dispatcher that builds the worker payload. It extracts the current
search criteria from the parent ResultSet and appends the target column name
before calling the background worker.

=cut

sub new {
    my ($class, %args) = @_;
    return bless {
        _resultset => $args{resultset},
        _column    => $args{column},
        _async_db  => $args{async_db},
    }, $class;
}

sub sum     { shift->_aggregate('sum')     }
sub max     { shift->_aggregate('max')     }
sub min     { shift->_aggregate('min')     }
sub avg     { shift->_aggregate('avg')     }
sub count   { shift->_aggregate('count')   }
sub average { shift->_aggregate('average') }

sub _aggregate {
    my ($self, $func) = @_;
    my $db = $self->{_async_db};

    my $payload = $self->{_resultset}->_build_payload();

    $payload->{column} = $self->{_column};

    # We reuse the parent ResultSet's bridge and payload logic
    return DBIx::Class::Async::_call_worker(
        $db,
        $func,
        $payload,
    );
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

    perldoc DBIx::Class::Async::ResultSetColumn

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

1; # End of DBIx::Class::Async::ResultSetColumn
