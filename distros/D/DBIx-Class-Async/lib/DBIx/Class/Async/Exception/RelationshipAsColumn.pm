package DBIx::Class::Async::Exception::RelationshipAsColumn;

$DBIx::Class::Async::Exception::RelationshipAsColumn::VERSION   = '0.64';
$DBIx::Class::Async::Exception::RelationshipAsColumn::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

use parent 'DBIx::Class::Async::Exception';

=head1 NAME

DBIx::Class::Async::Exception::RelationshipAsColumn - Exception for relationship
name passed where a column was expected

=head1 VERSION

Version 0.64

=head1 SYNOPSIS

    use DBIx::Class::Async::Exception::RelationshipAsColumn;

    DBIx::Class::Async::Exception::RelationshipAsColumn->throw(
        message           => "[DBIx::Class::Async] Relationship 'Details' passed where a column was expected",
        relationship      => 'Details',
        relationship_type => 'multi',
        source_class      => 'My::Schema::Result::Operation',
        operation         => 'update_or_create',
        hint              => "Omit 'Details' from the hashref if you have no related rows to insert.",
        original_error    => $raw_dbic_error,
    );

    # Catch specifically
    use Try::Tiny;
    try { ... } catch {
        if ( ref $_ && $_->isa('DBIx::Class::Async::Exception::RelationshipAsColumn') ) {
            warn sprintf "Relationship '%s' (type: %s) was passed as a column.\n%s\n",
                $_->relationship, $_->relationship_type, $_->hint;
        }
    };

=head1 DESCRIPTION

Thrown when a C<has_many>, C<belongs_to>, or C<might_have> relationship name is
used as a key in a create/update hashref with an C<undef> value, causing
L<DBIx::Class> to die internally with "No such column". This corresponds to
L<https://rt.cpan.org/Public/Bug/Display.html?id=127065|RT#127065>.

Inherits all methods from L<DBIx::Class::Async::Exception> and adds
L</relationship> and L</relationship_type>.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{relationship}      = $args{relationship};
    $self->{relationship_type} = $args{relationship_type} // 'relationship';
    return $self;
}

=head1 METHODS

Inherits C<throw>, C<rethrow>, C<message>, C<hint>, C<original_error>,
C<operation>, C<source_class>, and C<stacktrace> from
L<DBIx::Class::Async::Exception>.

=head2 relationship

    my $name = $exception->relationship;

The name of the relationship that was incorrectly passed as a column key,
e.g. C<'Details'>.

=cut

sub relationship      { $_[0]->{relationship}      }

=head2 relationship_type

    my $type = $exception->relationship_type;

The relationship accessor type, e.g. C<'multi'> (has_many), C<'single'>
(might_have / belongs_to), or C<'filter'>. Defaults to C<'relationship'> when
the type cannot be determined.

=cut

sub relationship_type { $_[0]->{relationship_type} }

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

    perldoc DBIx::Class::Async::Exception::RelationshipAsColumn

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

1; # End of DBIx::Class::Async::Exception::RelationshipAsColumn
