package DBIx::Schema::Changelog::Action::Tables;

=head1 NAME

DBIx::Schema::Changelog::Action::Tables - Action handler for tables

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';
use utf8;
use strict;
use warnings;
use Moose;
use MooseX::Types::Moose qw(HashRef Str);
use DBIx::Schema::Changelog::Action::Columns;
use DBIx::Schema::Changelog::Action::Constraints;

with 'DBIx::Schema::Changelog::Role::Action';

=head1 ATTRIBUTES

=over 4

=item templates

Stored parsed templates from main changelog file.

=cut

has templates => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

=item constraint_action

DBIx::Schema::Changelog::Action::Constraints object.

=cut

has constraint_action => (
    is      => 'ro',
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Constraints->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=item column_action

DBIx::Schema::Changelog::Action::Columns object.

=cut

has column_action => (
    is      => 'ro',
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Columns->new(
            driver => $self->driver(),
            dbh    => $self->dbh(),
          ),
          ;
    },
);

=item column_action

DBIx::Schema::Changelog::Action::Index object to add indices to the table.

=cut

has index_action => (
    is      => 'ro',
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Index->new(
            driver => $self->driver(),
            dbh    => $self->dbh(),
          ),
          ;
    },
);

=item prefix

Configurable prefix for table names.

=cut

has prefix => ( isa => Str, is => 'rw', default => '' );

=item postfix

Configurable postfix for table names.

=cut

has postfix => ( isa => Str, is => 'rw', default => '' );

=back

=head1 SUBROUTINES/METHODS

=over 4

=item add

Create new table.

=cut

sub add {
    my ( $self, $params ) = @_;
    return unless $params->{name};
    my $name    = $self->prefix() . $params->{name} . $self->postfix();
    my $actions = $self->driver()->actions;
    my $debug   = ( $params->{debug} ) ? 1 : 0;

    my @columns     = ();
    my $constraints = [];
    foreach my $col ( @{ $params->{columns} } ) {
        unless ( $col->{tpl} ) {
            $col->{table} = $params->{name};
            my $const = $self->constraint_action()->for_table( $col, $constraints );
            push( @columns, $self->column_action()->for_table( $col, $const ) );
            next;
        }
        use Data::Dumper;
        print Dumper($self);
        die "Called template $col->{tpl} is not defined" unless $self->templates()->{ $col->{tpl} };
        foreach ( @{ $self->templates()->{ $col->{tpl} } } ) {
            $_->{table} = $params->{name};
            my $const = $self->constraint_action()->for_table( $_, $constraints );
            push( @columns, $self->column_action()->for_table( $_, $const ) );
        }
    }

    $self->index_action()->for_table( $_, $constraints ) foreach @{ $params->{indices} };
    $self->constraint_action()->for_table( $_, $constraints ) foreach @{ $params->{constraints} };
    push( @columns, @$constraints );

    #prepare finaly created table to SQL
    my $sql = _replace_spare( $actions->{create_table},
        [ $name, join( ",\n\t", @columns ), $params->{engine}, $params->{charset} ] );

    #prepare finaly created table to SQL
    $self->_do($sql);

}

=item alter

Decides type of alter table
Run command of alter table

=cut

sub alter {
    my ( $self, $params ) = @_;
    return unless $params->{name};
    my $actions = $self->driver()->actions;
    my $sql =
      _replace_spare( $actions->{alter_table}, [ $params->{name} ] );
    if ( defined $params->{addcolumn} ) {
        foreach ( @{ $params->{addcolumn} } ) {
            $_->{table} = $params->{name};
            my $sql =
              _replace_spare( $actions->{alter_table}, [ $params->{name} ] );
            my $const = $self->constraint_action()->add($_);
            $self->_do( $sql . $self->column_action()->add( $_, $const ) );
        }
    }
    elsif ( defined $params->{altercolumn} ) {
        $self->column_action()->alter($params);
    }
    elsif ( defined $params->{dropcolumn} ) {
        $self->column_action()->drop($params);
    }
    elsif ( defined $params->{addconstraint} ) {
        unless ( $actions->{add_constraint} ) {
            print STDERR __PACKAGE__, ' (', __LINE__, '). Add constraint is not supported!', $/;
            return;
        }
        my $constraints = [];
        my $fk          = $params->{addconstraint};
        $fk->{table} = $params->{name};
        $self->constraint_action()->add( $fk, $constraints );
        $self->_do( $sql . ' ' . _replace_spare( $actions->{add_constraint}, [$_] ) ) foreach @$constraints;
    }
    else {
        die __PACKAGE__ . " Key to alter table not found or implemented.\n Probaply it is misspelled.";
    }
}

=item drop

Drop defined table.

=cut

sub drop {
    my ( $self, $params ) = @_;
    my $actions = $self->driver()->actions();
    my $sql = _replace_spare( $actions->{drop_table}, [ $params->{name} ] );
    $self->_do($sql);
}

=item list_from_schema 
    
Not needed!

=cut

sub list_from_schema {
    my ( $self, $schema ) = @_;
    my $tables = [];
    foreach ( @{ $self->do( $self->driver->actions->{list_tables}, [$schema] ) } ) {
        push(
            @$tables,
            {
                name    => $_->{table_name},
                type    => 'createtable',
                columns => $self->column_action->list_from_schema( $_->{table_name}, 'public' ),
            }
        );
    }
    return $tables;
}

=back

=head1 ADDITIONAL SUBROUTINES/METHODS

=over 4

=item load_templates

load pre defined column templates

=cut

sub load_templates {
    my ( $self, $templates ) = @_;
    foreach (@$templates) {
        my $tmp = [];
        foreach my $tpl ( @{ $_->{columns} } ) {
            if ( defined $tpl->{tpl} ) {
                die "Called template: '$tpl->{tpl}' is not defined"
                  unless $self->templates()->{ $tpl->{tpl} };
                push( @$tmp, @{ $self->templates()->{ $tpl->{tpl} } } );
                next;
            }
            push( @$tmp, $tpl );
        }
        $self->templates()->{ $_->{name} } = $tmp;
    }
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
