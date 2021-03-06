package DBIx::Schema::Changelog::Action::Constraint::ForeignKeys;

=head1 NAME

DBIx::Schema::Changelog::Action::Constraints - Action handler for constraint

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use utf8;
use strict;
use warnings;
use Time::HiRes qw/ time /;
use Moose;

with 'DBIx::Schema::Changelog::Role::Action';

=head1 SUBROUTINES/METHODS

=head2 add

=cut

sub add {
    my ( $self, $col, $constr_ref ) = @_;
    my $actions = $self->driver()->actions;
    die "Foreign key is not supported!", $/ unless $actions->{foreign_key};
    my $table     = '' . $col->{table};
    my $ref_table = $col->{foreign}->{reftable};
    my $name      = $col->{name};
    my $refcolumn = $col->{foreign}->{refcolumn};

    $table =~ s/"//g;
    $ref_table =~ s/"//g;
    $name =~ s/"//g;

    return _replace_spare(
        $actions->{foreign_key},
        [
            $col->{name},                 $ref_table,
            $col->{foreign}->{refcolumn}, "fkey_$table" . "_$refcolumn" . "_$name"
        ]
    );
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

=over 4

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

=item list_from_schema 
    
Not needed!

=cut

sub list_from_schema {
    my ( $self, $schema ) = @_;
    my $pkeys = [];
    foreach (
        @{ $self->do( $self->driver->actions->{list_table_foreign_keys}, [] ) }
      )
    {
        push(
            @$pkeys,
            {
                type          => 'altertable',
                name          => $_->{source_table},
                addconstraint => {
                    name    => $_->{source_column},
                    foreign => {
                        reftable  => $_->{target_table},
                        refcolumn => $_->{target_column}
                    }
                  }

            }
        );
    }
    return $pkeys;
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
