package DBIx::Class::Async::Exception::AmbiguousColumn;

$DBIx::Class::Async::Exception::AmbiguousColumn::VERSION   = '0.64';
$DBIx::Class::Async::Exception::AmbiguousColumn::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

use parent 'DBIx::Class::Async::Exception';

=head1 NAME

DBIx::Class::Async::Exception::AmbiguousColumn - Exception for column names
that are ambiguous across joined tables

=head1 VERSION

Version 0.64

=head1 SYNOPSIS

    use DBIx::Class::Async::Exception::AmbiguousColumn;

    DBIx::Class::Async::Exception::AmbiguousColumn->throw(
        message => "[DBIx::Class::Async] Ambiguous column 'status' - exists in multiple joined tables",
        column  => 'status',
        hint    => "Qualify the column: use 'me.status' for the primary table "
                 . "or 'relname.status' for a join.",
    );

    use Try::Tiny;
    try { ... } catch {
        if ( ref $_ && $_->isa('DBIx::Class::Async::Exception::AmbiguousColumn') ) {
            warn "Ambiguous column '" . $_->column . "': " . $_->hint;
        }
    };

=head1 DESCRIPTION

Thrown when a column name appears in multiple tables that are joined in a
query, and has not been qualified with a table alias such as C<me.column> or
C<relname.column>.

Inherits all methods from L<DBIx::Class::Async::Exception> and adds
L</column>.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{column} = $args{column};
    return $self;
}

=head1 METHODS

Inherits C<throw>, C<rethrow>, C<message>, C<hint>, C<original_error>,
C<operation>, C<source_class>, and C<stacktrace> from
L<DBIx::Class::Async::Exception>.

=head2 column

    my $col = $exception->column;

The name of the column that is ambiguous across joined tables, e.g. C<'status'>.

=cut

sub column { $_[0]->{column} }

=head1 SEE ALSO

L<DBIx::Class::Async::Exception>, L<DBIx::Class::Async::Exception::Factory>

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

    perldoc DBIx::Class::Async::Exception::AmbiguousColumn

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

1; # End of DBIx::Class::Async::Exception::AmbiguousColumn
