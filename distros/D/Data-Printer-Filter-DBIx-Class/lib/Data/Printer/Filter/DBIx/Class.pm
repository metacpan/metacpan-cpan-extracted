use strict;
use warnings;

package Data::Printer::Filter::DBIx::Class;
$Data::Printer::Filter::DBIx::Class::VERSION = '0.000004';
use Data::Printer::Filter;
use Scalar::Util qw(blessed);
use Term::ANSIColor;

# DBIx::Class filters
filter '-class' => sub {
    my ( $obj, $properties ) = @_;

    if ( $obj->isa( 'DBIx::Class::Row' ) ) {
        my %row = $obj->get_columns;
        return _add_prefix( $obj, $properties, [ \%row ] );
    }

    if ( $obj->isa( 'DBIx::Class::ResultSet' ) ) {
        my @rows;
        my $row_limit
            = defined $ENV{DDP_DBIC_ROW_LIMIT} ? $ENV{DDP_DBIC_ROW_LIMIT} : 5;

        while ( defined( my $row = $obj->next ) ) {

            # Could be inflating to a HashRef
            push @rows, blessed( $row )
                && $row->can( 'get_columns' ) ? { $row->get_columns } : $row;

            last if $row_limit && @rows == $row_limit;
        }
        my $msg = 'Showing all results';
        if ( $row_limit && @rows == $row_limit ) {
            $msg = sprintf( 'Showing first %i out of %i results.',
                scalar @rows, $obj->count );
        }

        return _add_prefix( $obj, $properties, \@rows, $msg );
    }

    return;
};

sub _add_prefix {
    my $obj        = shift;
    my $properties = shift;
    my $rows       = shift;
    my $msg        = shift;

    my $str = colored( ref( $obj ), $properties->{color}{class} );
    $str .= ' (' . $obj->result_class . ')' if $obj->can( 'result_class' );

    if ( $obj->can( 'as_query' ) ) {
        my $query_data = $obj->as_query;
        my @query_data = @$$query_data;
        indent;
        my $sql = shift @query_data;
        $str
            .= ' {'
            . newline
            . colored( $sql, 'bright_yellow' )
            . newline
            . join( newline,
            map { $_->[1] . ' (' . $_->[0]{sqlt_datatype} . ')' }
                @query_data );
        outdent;
        $str .= newline . '}';

    }

    $str .= ' (' . $msg . ')' if $msg;
    return $str . q{ } . np( $rows );
}
1;

=pod

=encoding UTF-8

=head1 NAME

Data::Printer::Filter::DBIx::Class - Apply special Data::Printer filters to DBIx::Class objects

=head1 VERSION

version 0.000004

=head1 SYNOPSIS

In your program:

    use Data::Printer filters => { -external => ['DBIx::Class'] };

or, in your C<.dataprinter> file:

    { filters => { -external => ['DBIx::Class'] } };

=head1 DESCRIPTION

Huge chunks of this have been lifted directly from L<Data::Printer::Filter::DB>
This filter differs in that it also adds the values from C<get_columns()> to
the output.  For a L<DBIx::Class::Row> object, the column values are return in
the data.  For a L<DBIx::Class::ResultSet>, by default the first 5 rows in the
ResultSet are returned, with the contents of C<get_columns()> included.  You
can change this behaviour via C<$ENV{DDP_DBIC_ROW_LIMIT}>.

    # Return up to 1,000 rows per ResultSet
    $ENV{DDP_DBIC_ROW_LIMIT} = 1000;

    # Return every row from every ResultSet
    $ENV{DDP_DBIC_ROW_LIMIT} = 0;

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

# ABSTRACT: Apply special Data::Printer filters to DBIx::Class objects

