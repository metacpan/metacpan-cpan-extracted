package DBIx::Schema::Changelog::Action::Constraints;

=head1 NAME

DBIx::Schema::Changelog::Action::Constraints - Action handler for constraint

=head1 VERSION

=over 4

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use utf8;
use strict;
use warnings;
use Time::HiRes qw/ time /;
use Moose;
use MooseX::HasDefaults::RO;
use DBIx::Schema::Changelog::Action::Constraint::ForeignKeys;
use DBIx::Schema::Changelog::Action::Constraint::PrimaryKeys;
use DBIx::Schema::Changelog::Action::Constraint::Uniques;

with 'DBIx::Schema::Changelog::Role::Action';

=back

=head1 ATTRIBUTES

=over 4

=item foreign_action

DBIx::Schema::Changelog::Action::Constraints object.

=cut

has foreign_action => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Constraint::ForeignKeys->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=item foreign_action

DBIx::Schema::Changelog::Action::Constraints object.

=cut

has unique_action => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Constraint::Uniques->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=item foreign_action

DBIx::Schema::Changelog::Action::Constraints object.

=cut

has primary_key_action => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Constraint::PrimaryKeys->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=back

=head1 SUBROUTINES/METHODS

=head2 add

=cut

sub add {
    my ( $self, $col ) = @_;
    my $actions = $self->driver()->actions;

    if ( defined $col->{foreign} ) {
        my $alter = _replace_spare( $actions->{alter_table}, [ $col->{table} ] );
        my $sql = $self->foreign_action->add($col);
        $sql = $alter . q~ ~ . _replace_spare( $actions->{add_constraint}, [$sql] );

        #prepare finaly created table to SQL
        return $self->_do($sql);
    }

    if ( defined $col->{primarykey} ) {
        my $alter = _replace_spare( $actions->{alter_table}, [ $col->{table} ] );
        my $sql = $self->primary_key_action->add($col);
        $sql = $alter . q~ ~ . _replace_spare( $actions->{add_constraint}, [$sql] );

        #prepare finaly created table to SQL
        return $self->_do($sql);
    }

}

=head2 alter

=cut

sub alter {
    my ( $self, $table_name, $col, $constr_ref ) = @_;

    #$self->table_action()->add($_)   if (uc $constraint->{type} eq 'NOT_NULL' );
    #$self->table_action()->drop($_)  if (uc $constraint_->{type} eq 'UNIQUE' );
    #$self->table_action()->alter($_) if (uc $constraint_->{type} eq 'PRIMARY' );
    #$self->index_action()->add($_)   if (uc $constraint_->{type} eq 'FOREIGN' );
    #$self->index_action()->alter($_) if (uc $constraint_->{type} eq 'CHECK' );
    #$self->index_action()->drop($_)  if (uc $constraint_->{type} eq 'DEFAULT' );
}

=head2 drop

=cut

sub drop {
    my ( $self, $table_name, $col, $constraints ) = @_;

    #$self->table_action()->add($_)   if (uc $constraint->{type} eq 'NOT_NULL' );
    #$self->table_action()->drop($_)  if (uc $constraint_->{type} eq 'UNIQUE' );
    #$self->table_action()->alter($_) if (uc $constraint_->{type} eq 'PRIMARY' );
    #$self->index_action()->add($_)   if (uc $constraint_->{type} eq 'FOREIGN' );
    #$self->index_action()->alter($_) if (uc $constraint_->{type} eq 'CHECK' );
    #$self->index_action()->drop($_)  if (uc $constraint_->{type} eq 'DEFAULT' );
}

=head2 for_table

Prepare column string for create table.
Or add new column into table

=cut

sub for_table {
    my ( $self, $col, $constr_ref, $debug ) = @_;
    if ( defined $col->{primarykey} && ref $col->{primarykey} eq 'ARRAY' ) {
        push( @$constr_ref, $self->primary_key_action->add($col) );
        return;
    }
    if ( defined $col->{unique} ) {
        push( @$constr_ref, $self->unique_action->add($col) );
        return;
    }

    push( @$constr_ref, $self->foreign_action->add($col) ) if ( defined $col->{foreign} );

    my $consts     = $self->driver()->constraints;
    my $not_null   = ( $col->{notnull} ) ? $consts->{not_null} : '';
    my $primarykey = ( defined $col->{primarykey} ) ? $consts->{primary_key} : '';
    return qq~$not_null $primarykey~;

}

=over 4

=item list_from_schema 
    
Not needed!

=cut

sub list_from_schema { }

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
