package DBIx::Schema::Changelog::Action::Sequences;

=head1 NAME

DBIx::Schema::Changelog::Action::Sequences - Action handler for sequences

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use strict;
use warnings;
use Moose;

with 'DBIx::Schema::Changelog::Role::Action';

=head1 SUBROUTINES/METHODS

=over 4

=item add

    Decides if autoincrement or to create a sequnece.
    Add sequences if it's needed

=cut

sub add {
    my ( $self, $params ) = @_;
    my $actions = $self->driver()->actions;

    die "Create sequence is not supported!"
      unless ( $actions->{create_sequence} );
    return $self->_create_sequence($params);
}

=item alter

Not yet implemented!

=cut

sub alter { }

=item drop

Not yet implemented!

=cut

sub drop { }

=item _create_sequence

=cut

sub _create_sequence {
    my ( $self, $params ) = @_;
    my $actions = $self->driver()->actions;
    die "Db connection iss missing!" unless ( $self->dbh() );
    my $table = $params->{table} || '';
    $table =~ s/"//g;
    $params->{name} =~ s/"//g;
    my $seq = ( $table eq '' ) ? $params->{name} : 'seq_' . $table . '_' . $params->{name};
    my $sql =
      _replace_spare( $actions->{create_sequence}, [ $seq, 1, 1, 9223372036854775807, 1, 1 ] );
    $self->_do($sql);
    return _replace_spare( $actions->{nextval_sequence}, [$seq] );
}

=item list_from_schema 
    
Not needed!

=cut

sub list_from_schema {
    my ( $self, $schema ) = @_;
    my $sequences = [];
    foreach ( @{ $self->do( $self->driver->actions->{list_sequences}, [] ) } ) {
        push(
            @$sequences,
            {
                type => 'createsequence',
                name => $_->{sequence_name},
            }
        );
    }
    return $sequences;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=back

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
