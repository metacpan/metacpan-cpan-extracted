package DBIx::Schema::Changelog::Role::Action;

=head1 NAME

DBIx::Schema::Changelog::Role::Action - Abstract action class.

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use utf8;
use strict;
use warnings FATAL => 'all';
use Moose::Role;

=head1 ATTRIBUTES

=head2 driver

	Loaded DBIx::Schema::Changelog::Driver module.

=cut

has driver => ( is => 'ro', );

=head2 driver

	Connected dbh object.

=cut

has dbh => ( is => 'ro', );

=head1 SUBROUTINES/METHODS

=head2 add

	Required sub to run add for specific action type.

=cut

requires 'add';

=head2 alter

	Required sub to run alter for specific action type.

=cut

requires 'alter';

=head2 drop

	Required sub to run drop for specific action type.

=cut

requires 'drop';

=head2 list_from_schema

	Required sub to run drop for specific action type.

=cut

requires 'list_from_schema';

=head1 SUBROUTINES/METHODS (private)

=head2 _replace_spare

	Replace spares which comes from DBIx::Schema::Changelog::Driver module.

=cut

sub _replace_spare {
    my ( $string, $options ) = @_;
    $string =~ s/\{(\d+)\}/$options->[$1]/g;
    return $string;
}

=head2 _do

	Running generated sql statements.

=cut

sub _do {
    my ( $self, $sql ) = @_;
    $self->dbh()->do($sql) or die "Can't handle sql: \n\t$sql\n $!";
}


=head2 do

    Running generated sql statements.

=cut

sub do {
    my ( $self, $statement, $options ) = @_;

    return $self->dbh->selectall_arrayref( $statement, { Slice => {} },
        @$options ) || die qq~$statement, $options~;
}

1;    # End of DBIx::Schema::Changelog::Role::Action

__END__

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

