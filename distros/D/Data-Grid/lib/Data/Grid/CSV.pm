package Data::Grid::CSV;

use 5.014;
use strict;
use warnings FATAL => 'all';

use Moo;

extends 'Data::Grid';

use Text::CSV;

=head1 NAME

Data::Grid::CSV - CSV driver for Data::Grid

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.07';

=head2 new

=cut

has _csv => (
    is       => 'ro',
    required => 1,
);

around BUILDARGS => sub {
    my ($orig, $class, @rest) = @_;

    # normalize the params
    my $p = (@rest && ref $rest[0] eq 'HASH') ? $rest[0] : { @rest };
    my $o = $p->{options} || { binary => 1 };

    unless ($o->{sep_char} || $o->{sep}) {
        my $fh = $p->{fh};
        my ($commas, $tabs, $i) = (0, 0, 0);

        # we need to detect the damn thing; scan up to 10 lines
        seek $fh, 0, 0;

        while ($i++ < 10 && (my $line = <$fh>)) {
            # goatse operator will squash to a count
            $commas += () = $line =~ /,/g;
            $tabs   += () = $line =~ /\t/g;
        }
        seek $fh, 0, 0;

        $o->{sep_char} = $commas > $tabs ? ',' : "\t";
    }

    # instantiate the csv driver
    $p->{_csv} = Text::CSV->new($o) or die $!;

    $class->$orig($p);
};

=head2 tables

=cut

sub tables {
    my $self = shift;

    my %p = $self->table_params(0);

    # require Data::Dumper;
    # warn Data::Dumper::Dumper(\%p);

    my @table = ($self->table_class->new(%p));
}

=head2 table_class

=cut

has '+table_class' => (
    default => 'Data::Grid::CSV::Table',
);

=head2 row_class

=cut

has '+row_class' => (
    default => 'Data::Grid::CSV::Row',
);

=head2 cell_class

=cut

has '+cell_class' => (
    default => 'Data::Grid::CSV::Cell',
);

package Data::Grid::CSV::Table;

use Moo;

extends 'Data::Grid::Table';

# sub BUILD {
#     my $self = shift;

#     # here is where we process
# }

# has '+header' => (
#     trigger => sub {
#         my ($self, $val) = @_;
#     },
# );

# has '+cursor' => (
#     trigger => sub {
#         warn "hi lol $_[1] -> " . $_[0]->cursor;
#     },
# );

# byte offset cache
has _cache => (
    is      => 'ro',
    default => sub { [0] },
);

sub rewind {
    my $self = shift;
    # we actually want to seek the file to the position after the offset

    my $p     = $self->parent;
    my $fh    = $p->fh;
    my $csv   = $p->_csv;
    my $off   = $self->_offset;
    my $cache = $self->_cache;

    if (defined $cache->[$off]) {
        seek $fh, $cache->[$off], 0;
    }
    else {
        seek $fh, 0, 0;
        # start this at 1 because we already have position 0 (it's 0)
        for my $i (1..$off) {
            $csv->getline($fh);
            last if eof $fh or $csv->eof;
            $cache->[$i] = tell $fh;
        }
        # fh position will now be on the first (desired) record
    }

    $self->_set_cursor($off);
}

sub next {
    my $self = shift;
    my $p   = $self->parent;
    my $fh  = $p->fh;
    my $csv = $p->_csv;

    my $cache  = $self->_cache;
    my $cursor = $self->cursor;

    if (defined (my $pos = $cache->[$cursor])) {
        seek $fh, $pos, 0;
    }

    # attempt to get the row
    my $row = $csv->getline($fh);
    return if !$row and $csv->eof;

    # i guess $csv->eof doesn't get set until after you hit the file's eof
    $cache->[$cursor + 1] //= tell $fh unless eof $fh;

    # clean up and get out of here
    $self->_set_cursor($cursor + 1);

    $p->row_class->new($self, $cursor, $row) if defined wantarray;
}

package Data::Grid::CSV::Row;

use Moo;

extends 'Data::Grid::Row';

sub cells {
    my ($self, $flatten) = @_;

    my $class = $self->parent->parent->cell_class;
    my @cells = @{$self->proxy || [] };

    @cells = map { $class->new($self, $_, $cells[$_]) } (0..$#cells);

    wantarray ? @cells : \@cells;
}

package Data::Grid::CSV::Cell;

use Moo;

extends 'Data::Grid::Cell';

sub value {
    $_[0]->proxy;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 SEE ALSO

=over 4

=item

L<Data::Grid>

=item

L<Text::CSV_XS>

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

1; # End of Data::Grid::CSV
