package DBIx::Schema::Changelog::Action::Columns;

=head1 NAME

DBIx::Schema::Changelog::Action::Columns - Action handler for table columns

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use utf8;
use strict;
use warnings;
use Moose;
use MooseX::HasDefaults::RO;
use DBIx::Schema::Changelog::Action::Constraints;
use DBIx::Schema::Changelog::Action::Column::Defaults;

with 'DBIx::Schema::Changelog::Role::Action';

=head1 ATTRIBUTES

=over 4

=item default

DBIx::Schema::Changelog::Action::Constraints object.

=cut

has default => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Column::Defaults->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=back

=head1 SUBROUTINES/METHODS

=over 4

=item add

    Prepare column string for create table.
    Or add new column into table

=cut

sub add {
    my ( $self, $col, $constraint, $debug ) = @_;
    my $actions = $self->driver()->actions;
    my $type    = $self->driver()->type($col);
    die "Add column is not supported!" unless ( $actions->{add_column} );

    my $must_nn = ( defined $col->{primarykey} ) ? 1 : 0;
    die "No default value set for $col->{name}" if ($must_nn);
    my $default = $self->default->add($col);
    my $ret =
      _replace_spare( $actions->{add_column}, [qq~$col->{name} $type $constraint $default~] );
    return $ret;

}

=item alter

    Not yet implemented

=cut

sub alter {
    my ( $self, $params ) = @_;
    print STDERR __PACKAGE__, " (", __LINE__, ") Alter column is not supported!", $/;
    return undef;
}

=item drop

    If it's supported, it will drop defined column from table.

=cut

sub drop {
    my ( $self, $params ) = @_;
    my $actions = $self->driver()->actions;
    unless ( $actions->{drop_column} ) {
        print STDERR __PACKAGE__, " (", __LINE__, ") Drop column is not supported!", $/;
        return;
    }
    foreach ( @{ $params->{dropcolumn} } ) {
        my $s = _replace_spare( $actions->{alter_table}, [ $params->{name} ] );
        $s .= ' ' . _replace_spare( $actions->{drop_column}, [ $_->{name} ] );
        $self->_do($s);
    }

}

=item key_from_value

Create new table.

=cut

sub key_from_value {
    my ( $fruit, $col ) = @_;
    my @result;
    for my $key ( keys %$fruit ) {
        if ( ref $fruit->{$key} eq 'ARRAY' ) {
            for ( @{ $fruit->{$key} } ) {
                push @result, $key if /^$col$/i;
            }
        }
        else {
            push @result, $key if $fruit->{$key} =~ /^$col$/i;
        }
    }
    return @result;
}

=item list_from_schema 
    
Not needed!

=cut

sub list_from_schema {
    my ( $self, $table, $schema ) = @_;

    my $cols = [];
    foreach (
        @{
            $self->do( $self->driver->actions->{list_table_columns},
                [ $table, $schema ] )
        }
      )
    {
        my ($key) = key_from_value( $self->driver->types, $_->{data_type} );
        my $column = {
            name => $_->{column_name},
            type => $key,
        };
        if ( defined $_->{column_default} ) {
            $column->{default} =
              $self->driver->parse_default( $_->{column_default} );
        }

        $column->{length} = $_->{character_maximum_length}
          if ( defined $_->{character_maximum_length} );
        push( @$cols, $column );
    }
    return $cols;
}

=item for_table

    Prepare column string for create table.
    Or add new column into table

=cut

sub for_table {
    my ( $self, $col, $constraint ) = @_;
    my $must_nn      = ( defined $col->{primarykey} ) ? 1 : 0;
    my $hash_default = ( defined $col->{default} )    ? 1 : 0;
    die "No default value set for $col->{name}" if ( $must_nn && !$hash_default );
    my $default = $self->default->add($col);
    my $type    = $self->driver()->type($col);
    return $col->{name} . ' ' . $type . ' ' . $constraint . ' ' . $default;

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
