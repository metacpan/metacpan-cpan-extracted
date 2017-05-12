
package DBIx::BlackBox::Result;

use Moose;
use namespace::autoclean;

=encoding utf8

=head1 NAME

DBIx::BlackBox::Result - result of executed stored procedure.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $rs = $dbbb->exec('ListCatalogs',
            root_id => $root_id,
            org_id => $org_id,
        );
    }

=head1 ATTRIBUTES

=head2 db_driver

Database driver object.

isa: L<DBIx::BlackBox::Driver>.

=cut

has 'db_driver' => (
    is => 'rw',
    isa => 'DBIx::BlackBox::Driver',
);


=head2 sth

Statement handle for current result.

isa: L<DBI::st>.

=cut

has 'sth' => (
    is => 'rw',
    isa => 'DBI::st',
);

has '_procedure_result' => (
    is => 'rw',
    isa => 'Maybe[Int]',
    predicate => 'has_procedure_result',
);

=head2 resultsets

    print "$_\n" for @{ $rs->resultsets };

Names of the resultsets classes.

isa: C<ArrayRef>.

=cut

has 'resultsets' => (
    is => 'rw',
    isa => 'ArrayRef',
);

=head2 idx

    if ( $rs->idx == 1 ) {
        ...
    }

Index of the current resultset.

isa: C<Int>.

=cut

has 'idx' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

=head1 METHODS

=head2 next_resultset

    do {
        ...
    } while ( $rs->next_resultset );

Returns true if database statement has more resultsets and it is a row
result (SELECT query).

=cut

sub next_resultset {
    my $self = shift;

    if ( $self->db_driver->has_more_result_sets($self->sth) ) {
        $self->idx( $self->idx + 1 );
        if ( $self->db_driver->result_type($self->sth) eq 'row_result' ) {
            return 1;
        };
    }
    return 0;
}

=head2 next_row

    while ( my $row = $rs->next_row ) {
        ...
    }

Tries to fetch next row and returns instance of an object of the current
resultset (provided by L<"resultsets">.

Returns undef if there are no rows.

=cut

sub next_row {
    my $self = shift;

    my @columns = $self->db_driver->columns( $self->sth );

    if ( my $row = $self->sth->fetch ) {
        if ( $self->db_driver->result_type( $self->sth ) eq 'row_result' ) {
            if ( my $class = $self->resultsets->[ $self->idx ] ) {
                my @data = @$row;
                
                my %args = map { shift @columns, $_ } @$row;

                return $class->new( %args );
            };
        }
    };

    return;
}

=head2 procedure_result

Returns return value of executed stored procedure.

=cut

sub procedure_result {
    my $self = shift;

    unless ( $self->has_procedure_result ) {
        if ( $self->db_driver->result_type( $self->sth ) eq 'status_result' ) {
            my $res = $self->sth->fetch->[0];
            $self->_procedure_result( $res );
            $self->sth->finish;
        }
    };

    return $self->_procedure_result;
}

=head2 all
    
    my ( $catalogs, $data, $rv ) = $rs->all;

Helper method to get all rows of all resultsets at once.

=cut

sub all {
    my $self = shift;

    my @result_sets = ();

    do {
        while ( my $row = $self->next_row ) {
            push @{ $result_sets[ $self->idx ] }, $row;
        }
    } while ( $self->next_resultset );

    return ( @result_sets, $self->procedure_result );
}

=head1 AUTHOR

Alex J. G. Burzyński, E<lt>ajgb at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Alex J. G. Burzyński.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;


