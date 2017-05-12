package Cassandra::Client::ResultSet;
use 5.010;
use strict;
use warnings;

=pod

=head1 NAME

Cassandra::Client::ResultSet - container for rows returned from a query

=head1 METHODS

=over

=cut

sub new {
    my ($class, $rows, $headers, $next_page)= @_;

    return bless {
        rows => $rows,
        headers => $headers,
        next_page => $next_page,
    }, $class;
}

=item $result->rows()

Returns an arrayref of all rows in the ResultSet. Each row will be represented as an arrayref with cells. To find column names, see C<column_names>.

=cut

sub rows {
    $_[0]{rows}
}

=item $result->row_hashes()

Returns an arrayref of all rows in the ResultSet. Each row will be represented as a hashref with cells.

=cut

sub row_hashes {
    my $self= shift;
    my $rows= $self->rows;
    my @names= @{$self->column_names};

    my @result;

    for my $row (@$rows) {
        my $newrow= {};
        @{$newrow}{@names}= @$row;
        push @result, $newrow;
    }

    return \@result;
}

=item $result->column_names()

Returns an arrayref with the names of the columns in the result set, to be used with rows returned from C<rows()>.

=cut

sub column_names {
    $_[0]{headers}
}

=item $result->next_page()

Returns a string pointing to the next Cassandra result page, if any. Used internally by C<< $client->each_page() >>, but can be used to implement custom pagination logic.

=cut

sub next_page {
    $_[0]{next_page}
}

=back

=cut

1;
