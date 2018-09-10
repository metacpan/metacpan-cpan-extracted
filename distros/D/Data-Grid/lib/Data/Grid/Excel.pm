package Data::Grid::Excel;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Moo;

use Spreadsheet::ParseExcel;
use Carp ();

extends 'Data::Grid';

=head1 NAME

Data::Grid::Excel - Excel (original OLE format) driver for Data::Grid

=head1 VERSION

Version 0.02_01

=cut

our $VERSION = '0.02_01';

=head1 METHODS

=head2 new

=cut

has _proxy => (
    is => 'rwp',
);

sub _init {
    my ($self, $options) = @_;

    my $driver = Spreadsheet::ParseExcel->new(%$options);
    $driver->parse($self->fh) or Carp::croak($driver->error);
}

sub BUILD {
    my ($self, $p) = @_;

    my $options = ref $p->{options} eq 'HASH' ? $p->{options} : {};

    $self->_set__proxy($self->_init($options));
}

=head2 tables

=cut

sub tables {
    my $self = shift;

    my $p  = $self->_proxy;
    my $tc = $self->table_class;
    my @ws = $p->worksheets;

    my @tables;
    for my $i (0..$#ws) {
        my %p = $self->table_params($i);
        push @tables, $tc->new(%p, proxy => $ws[$i]);
    }

    # do this for overload
    wantarray ? @tables : \@tables;
}

=head2 table_class

=cut

has '+table_class' => (
    default => 'Data::Grid::Excel::Table',
);

=head2 row_class

=cut

has '+row_class' => (
    default => 'Data::Grid::Excel::Row',
);

=head2 cell_class

=cut

has '+cell_class' => (
    default => 'Data::Grid::Excel::Cell',
);

package Data::Grid::Excel::Table;

use Moo;

extends 'Data::Grid::Table';

sub rewind {
    $_[0]->_set_cursor($_[0]->_offset);
}

sub next {
    my $self = shift;
    my $cursor = $self->cursor;
    my ($minr, $maxr) = $self->proxy->row_range;

    return unless $maxr - $minr > 0 and $cursor + $minr <= $maxr;

    $self->_set_cursor($cursor + 1);

    # only bother with this if there is a caller
    $self->parent->row_class->new($self, $cursor, $minr + $cursor)
        if defined wantarray;
}

package Data::Grid::Excel::Row;

use Moo;

extends 'Data::Grid::Row';

sub cells {
    my ($self, $flatten) = @_;

    my $p     = $self->parent;
    my $class = $p->parent->cell_class;
    my $row   = $p->proxy;

    my ($minc, $maxc) = $row->col_range;
    my @cells;
    for (my $c = 0; $c <= $maxc - $minc; $c++) {
        my $cell = $row->get_cell($self->proxy, $c);
        push @cells, $flatten ? $cell->value : $class->new($self, $c, $cell);
    }

    # do this for overload
    wantarray ? @cells : \@cells;
}

package Data::Grid::Excel::Cell;

use Moo;

extends 'Data::Grid::Cell';

sub value {
    $_[0]->proxy->value if defined $_[0]->proxy;
}

sub literal {
    $_[0]->proxy->unformatted if defined $_[0]->proxy;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 SEE ALSO

=over 4

=item

L<Data::Grid>

=item

L<Spreadsheet::ReadExcel>

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


1; # End of Data::Grid::Excel
