package Data::Grid::Row;

use 5.012;
use strict;
use warnings FATAL => 'all';


use Moo;

use overload '@{}' => 'cells';
# lol this doesn't work with moo
#use overload '%{}' => 'as_hash';

extends 'Data::Grid::Container';

=head1 NAME

Data::Grid::Row - Row implementation for Data::Grid::Table

=head1 VERSION

Version 0.02_01

=cut

our $VERSION = '0.02_01';

=head1 SYNOPSIS

    # CSV files are themselves only a single table, so the list
    # context assignment here takes the first and only one.
    my ($table) = Data::Grid->parse('foo.csv')->tables;

    while (my $row = $table->next) {
        my @cells = $row->cells;
        # or
        @cells = @$row;

        # or, if column names were supplied somehow:

        my %cells = $row->as_hash;
        # or
        %cells = %$row;
    }

=head1 METHODS

=head2 table

Retrieve the L<Data::Grid::Table> object to which this row
belongs. Alias for L<Data::Grid::Container/parent>.

=cut

sub table {
    $_[0]->parent;
}

=head2 cells [$FLATTEN]

Retrieve the cells from the row, as an array in list context or
arrayref in scalar context. The array dereferencing operator C<@{}> is
also overloaded and works like this:

    my @cells = @$row;

=cut

sub cells {
    Carp::croak("This method is a stub; it must be overridden!");
}

=head2 width

Returns the width of the row in columns. This is the same as C<scalar
@{$row->cells}>.

=cut

sub width {
    # flatten the cells, because no sense in spending any effort
    # computing results that get immediately thrown away
    scalar @{$_[0]->cells(1)};
}

=head2 as_hash [$FLATTEN]

If the table has a heading or its columns were designated in the
constructor or with L<Data::Grid::Table/columns>, this method will
return the row as key-value pairs in list context and a HASH reference
in scalar context. If there is no column spec, this method will
generate dummy column names starting from 1, like C<col1>, C<col2>,
etc. It will also fill in the blanks if the column spec is shorter
than the actual row. If the column spec is longer, the overhang will
be populated with C<undef>s. As well it is worth noting that duplicate
keys will be clobbered with the rightmost value at this time, though
that behaviour may change.

=cut

sub as_hash {
    my ($self, $flatten) = @_;

    my @cells = $self->cells;
    my @cols  = $self->parent->columns;

    # XXX this should probably be the global width but whatev
    @cols = map { "col$_" } (1..scalar @cells) unless @cols;

    my %out;
    for my $i (0..$#cols) {
        $out{$cols[$i]} = ($flatten && ref $cells[$i]) ?
            $cells[$i]->value : $cells[$i];
    }
    wantarray ? %out : \%out;
}

=head2 as_string

Returns the row as CSV, quoted where necessary, minus the newline.

=cut

sub as_string {
    join ',', map { $_->quoted } $_[0]->cells;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 SEE ALSO

=over 4

=item

L<Data::Grid>

=item

L<Data::Grid::Container>

=item

L<Data::Grid::Table>

=item

L<Data::Grid::Cell>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010-2018 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Data::Grid::Row
