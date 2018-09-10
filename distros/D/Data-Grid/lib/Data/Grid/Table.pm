package Data::Grid::Table;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Moo;

use overload '<>'  => "next";
use overload '@{}' => "rows";

use Types::Standard  qw(slurpy Undef Bool Int Str Maybe Optional ArrayRef);
use Types::XSD::Lite qw(PositiveInteger NonNegativeInteger);
use Type::Params     qw(compile multisig Invocant);

extends 'Data::Grid::Container';

=encoding utf8

=head1 NAME

Data::Grid::Table - A table implementation for Data::Grid

=head1 VERSION

Version 0.02_01

=cut

our $VERSION = '0.02_01';

=head1 SYNOPSIS

    my $grid = Data::Grid->parse('arbitrary.csv');

    # Just take the first one, since a CSV will only have one table.
    my ($table) = $grid->tables;

    while (my $row = $table->next) {
        # do some stuff
    }

    # or

    while (my $row = <$table>) {
        # ...
    }

    # or

    my @rows = $table->rows;

    # or

    my @rows = @$table;

=head1 METHODS

=head2 new

=cut

sub BUILD {
    my $self = shift;

    # set initial columns
    my @ic = @{$self->_init_cols};
    $self->columns(@ic) if @ic;

    $self->ffwd($self->start);

    if ($self->header and my $hdr = $self->next) {
        # set the columns to the header in the absence of supplied columns

        my @hdr = map { $_->value } @$hdr;

        $self->columns(@hdr) unless @ic;
    }

    $self->ffwd($self->skip);

    return;
}

=over 4

=item start

This non-negative integer offset tells the table to skip the first N
rows, I<before> looking for any header. Defaults to zero.

=cut

has start => (
    is      => 'rw',
    isa     => NonNegativeInteger,
    default => 0,
);

=item header

This flag tells us that the first (logical) row is a header. Defaults
to false.

=cut

has header => (
    is      => 'rw',
    isa     => Bool,
    coerce  => sub { int !!$_[0] },
    default => 0,
);

=item skip

This offset tells us to skip N rows I<after> any header. Defaults to
zero.

=cut

has skip => (
    is      => 'rw',
    isa     => NonNegativeInteger,
    default => 0,
);

=item columns

This C<ARRAY> reference of columns will be used in lieu of, or I<instead>
of, any header row. Columns (or the header row)

=cut

# we save the explicit initial columns as a separate member
has _init_cols => (
    is       => 'ro',
    isa      => ArrayRef[Str],
    default  => sub { [] },
    init_arg => 'columns',
);

has _columns => (
    is       => 'ro',
    default  => sub { [] },
    init_arg => undef,
);

sub columns {
    state $check = Type::Params::multisig(
        [Invocant],
        [Invocant, Undef],
        [Invocant, slurpy ArrayRef[Str]]);
    my ($self, @args) = $check->(@_);
    my $cols = $self->_columns;

    # no args? this is an accessor
    return wantarray ? @$cols : [@$cols] unless @args;

    my @old = @$cols;
    @{$self->_init_cols} = @$cols = defined $args[0] ? @{$args[0]} : ();

    wantarray ? @old : \@old;
}

=back

=head2 cursor

Returns the row offset as an integer starting with zero, which is the
beginning of the table I<irrespective> of offsets like L</start>,
L</header>, and L</skip>. Not to be confused with
L<Data::Grid::Container/position>.

=cut

sub _offset {
    my $self = shift;
    $self->start + $self->header + $self->skip;
}

has cursor => (
    is       => 'rwp',
    isa      => NonNegativeInteger,
    default  => 0,
    init_arg => undef,
);


=head2 next

Retrieves the next row in the table or C<undef> when it reaches the
end. This method L<must be overridden> by a driver subclass. The
iteration operator C<<>> is also overloaded for table objects, so you
can use it like this:

    while (my $row = <$table>) { ...

=cut

sub next {
    Carp::croak("This method is a stub; it must be overridden!");
}

=head2 first

Returns the first row in the table, and is equivalent to calling
L</rewind> and then L</next>.

=cut

sub first {
    my $self = shift;
    $self->rewind;
    $self->next;
}

=head2 rewind

Sets the table's cursor back to the first row. Returns the previous
position, beginning at zero. This method I<must be overridden> by a
driver subclass.

=cut

sub rewind {
    Carp::croak("This method is a stub; it must be overridden!");
}

=head2 ffwd $ROWS

Fast forward by C<$ROWS> and return what is there.

=cut

sub ffwd {
    state $check = Type::Params::compile(Invocant, NonNegativeInteger);

    my ($self, $rows) = $check->(@_);
    return unless $rows;

    # call in void context to skip the overhead of constructing the row
    $self->next while $rows-- > 1;

    $self->next; # returning the last one
}

=head2 rows [$FLATTEN];

Retrieves an array of rows all at once. This method overloads the
array dereferencing operator C<@{}>, so you can use it like this:

    my @rows = @$table;

Note that this implementation is I<extremely naïve> and you will
almost invariably want to override it in a subclass.

=cut

sub rows {
    my ($self, $flatten) = @_;
    my @rows;

    $self->rewind;
    while (my $row = $self->next) {
        push @rows, $flatten ? scalar $row->cells(1) : $row;
    }
    $self->rewind;

    wantarray ? @rows : \@rows;
}

# =head2 columns

# =cut

# =head2 width

# Gets the width, in columns, of the table.

# =cut

=head2 height

Gets the height, in rows, of the table. Careful, for drivers that only
do sequential access, this means iterating over the whole set, so you
might as well.

This implementation is naïve; please override it in a subclass.

=cut

sub height {
    # overloaded lol
    scalar @{$_[0]};
}

=head2 as_string

Returns the table as CSV.

=cut

sub as_string {
    my $self = shift;
    my $out = '';
    $self->rewind;

    while (my $row = $self->next) {
        $out .= $row->as_string . "\n";
    }

    $out;
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

L<Data::Grid::Row>

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

1; # End of Data::Grid::Table
