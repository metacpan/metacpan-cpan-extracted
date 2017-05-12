package Data::Frame;
# ABSTRACT: data frame implementation
$Data::Frame::VERSION = '0.003';
use strict;
use warnings;

use Tie::IxHash;
use Tie::IxHash::Extension;
use PDL::Lite;
use Data::Perl ();
use List::AllUtils;
use Try::Tiny;
use PDL::SV;
use PDL::StringfiableExtension;
use Carp;
use Scalar::Util qw(blessed);

use Text::Table::Tiny;

use Data::Frame::Column::Helper;

use overload (
		'""'   =>  \&Data::Frame::string,
		'=='   =>  \&Data::Frame::equal,
		'eq'   =>  \&Data::Frame::equal,
	);

{
	# TODO temporary column role
	no strict;
	*PDL::number_of_rows = sub { $_[0]->getdim(0) };
	*Data::Perl::Collection::Array::number_of_rows = sub { $_[0]->count };
}

use Moo;
with 'MooX::Traits';

sub _trait_namespace { 'Data::Frame::Role' } # override for MooX::Traits

has _columns => ( is => 'ro', default => sub { Tie::IxHash->new; } );

has _row_names => ( is => 'rw', predicate => 1 );

sub BUILD {
	my ($self, $args) = @_;
	my $colspec = delete $args->{columns};

	if( defined $colspec ) {
		my @columns =
			  ref $colspec eq 'HASH'
			? map { ($_, $colspec->{$_} ) } sort { $a cmp $b } keys %$colspec
			: @$colspec;
		$self->add_columns(@columns);
	}
}

sub string {
	my ($self) = @_;
	my $rows = [];
	push @$rows, [ '', @{ $self->column_names } ];
	for my $r_idx ( 0..$self->number_of_rows-1 ) {
		my $r = [
			$self->row_names->slice($r_idx)->squeeze->string,
			map {
				my $col = $self->nth_column($_);
				$col->slice($r_idx)->squeeze->string
			} 0..$self->number_of_columns-1 ];
		push @$rows, $r;
	}
	{
		# clear column separators
		local $Text::Table::Tiny::COLUMN_SEPARATOR = '';
		local $Text::Table::Tiny::CORNER_MARKER = '';

		Text::Table::Tiny::table(rows => $rows, header_row => 1)
	}
}

sub number_of_columns {
	my ($self) = @_;
	$self->_columns->Length;
}

sub number_of_rows {
	my ($self) = @_;
	if( $self->number_of_columns ) {
		return $self->nth_column(0)->number_of_rows;
	}
	0;
}

# supports negative indices
sub nth_column {
	my ($self, $index) = @_;
	confess "requires index" unless defined $index;
	confess "column index out of bounds" if $index >= $self->number_of_columns;
	# fine if $index < 0 because negative indices are supported
	$self->_columns->Values( $index );
}

sub column_names {
	my ($self, @colnames) = @_;
	if( @colnames ) {
		try {
			$self->_columns->RenameKeys( @colnames );
		} catch {
			confess "incorrect number of column names" if /@{[ Tie::IxHash::ERROR_KEY_LENGTH_MISMATCH ]}/;
		};
	}
	[ $self->_columns->Keys ];
}

sub row_names {
	my ($self, @rest) = @_;
	if( @rest ) {
		# setting row names
		my $new_rows;
		if( ref $rest[0] ) {
			if( ref $rest[0] eq 'ARRAY' ) {
				$new_rows = Data::Perl::array( @{ $rest[0] });
			} elsif( $rest[0]->isa('PDL') ) {
				# TODO just run uniq?
				$new_rows = Data::Perl::array( @{ $rest[0]->unpdl } );
			} else {
				$new_rows = Data::Perl::array(@rest);
			}
		} else {
			$new_rows = Data::Perl::array(@rest);
		}

		confess "invalid row names length"
			if $self->number_of_rows != $new_rows->count;
		confess "non-unique row names"
			if $new_rows->count != $new_rows->uniq->count;

		return $self->_row_names( PDL::SV->new($new_rows) );
	}
	if( not $self->_has_row_names ) {
		# if it has never been set before
		return sequence($self->number_of_rows);
	}
	# else, if row_names has been set
	return $self->_row_names;
}

sub _make_actual_row_names {
	my ($self) = @_;
	if( not $self->_has_row_names ) {
		$self->_row_names( $self->row_names );
	}
}

sub column {
	my ($self, $colname) = @_;
	confess "column $colname does not exist" unless $self->_columns->EXISTS( $colname );
	$self->_columns->FETCH( $colname );
}

sub _column_validate {
	my ($self, $name, $data) = @_;
	if( $name =~ /^\d+$/  ) {
		confess "invalid column name: $name can not be an integer";
	}
	if( $self->number_of_columns ) {
		if( $data->number_of_rows != $self->number_of_rows ) {
			confess "number of rows in column is @{[ $data->number_of_rows ]}; expected @{[ $self->number_of_rows ]}";
		}
	}
	1;
}

sub add_columns {
	my ($self, @columns) = @_;
	confess "uneven number of elements for column specification" unless @columns % 2 == 0;
	for ( List::AllUtils::pairs(@columns) ) {
		my ( $name, $data ) = @$_;
		$self->add_column( $name => $data );
	}
}

sub add_column {
	my ($self, $name, $data) = @_;
	confess "column $name already exists"
		if $self->_columns->EXISTS( $name );

	# TODO apply column role to data
	$data = PDL::SV->new( $data ) if ref $data eq 'ARRAY';

	$self->_column_validate( $name => $data);


	$self->_columns->Push( $name => $data );
}

# R
# > iris[c(1,2,3,3,3,3),]
# PDL
# $ sequence(10,4)->dice(X,[0,1,1,0])
sub select_rows {
	my ($self, @which_rest) = @_;

	my $which = [];
	if( @which_rest > 1 ) {
		$which = \@which_rest; # array to arrayref
	} elsif( @which_rest == 1 ) {
		$which = $which_rest[0]; # get the first value off
	} else { # @which_rest == 0
		$which = pdl []; # Empty PDL
	}

	$which = PDL::Core::topdl($which); # ensure it is a PDL

	my $colnames = $self->column_names;
	my $colspec = [ map {
		( $colnames->[$_] => $self->nth_column($_)->dice($which) )
	} 0..$self->number_of_columns-1 ];

	$self->_make_actual_row_names;
	my $select_df = $self->new(
		columns => $colspec,
		_row_names => $self->row_names->dice( $which ) );
	$select_df;
}

sub _column_helper {
	my ($self) = @_;
	Data::Frame::Column::Helper->new( dataframe => $self );
}

sub equal {
	my ($self, $other, $d) = @_;
	if( blessed($self) && $self->isa('Data::Frame') && blessed($other) && $other->isa('Data::Frame') ) {
		if( $self->number_of_columns == $other->number_of_columns ) {
			my @eq_cols = map { $self->nth_column($_) == $other->nth_column($_) }
					0..$self->number_of_columns-1;
			my @colnames = @{ $self->columns };
			my @colspec = List::AllUtils::mesh( @colnames, @eq_cols );
			return $self->new( columns => \@colspec );
		} else {
			die "number of columns is not equal: @{[$self->number_of_columns]} != @{[$other->number_of_columns]}";
		}
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame - data frame implementation

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Data::Frame;
    use PDL;

    my $df = Data::Frame->new( columns => [
        z => pdl(1, 2, 3, 4),
        y => ( sequence(4) >= 2 ) ,
        x => [ qw/foo bar baz quux/ ],
    ] );

    say $df;
    # ---------------
    #     z  y  x
    # ---------------
    #  0  1  0  foo
    #  1  2  0  bar
    #  2  3  1  baz
    #  3  4  1  quux
    # ---------------

    say $df->nth_column(0);
    # [1 2 3 4]

    say $df->select_rows( 3,1 )
    # ---------------
    #     z  y  x
    # ---------------
    #  3  4  1  quux
    #  1  2  0  bar
    # ---------------

=head1 DESCRIPTION

This implements a data frame container that uses L<PDL> for individual columns.
As such, it supports marking missing values (C<BAD> values).

The API is currently experimental and is made to work with
L<Statistics::NiceR>, so be aware that it could change.

=head1 METHODS

=head2 new

    new( Hash %options ) # returns Data::Frame

Creates a new C<Data::Frame> when passed the following options as a
specification of the columns to add:

=over 4

=item * columns => ArrayRef $columns_array

When C<columns> is passed an C<ArrayRef> of pairs of the form

    $columns_array = [
        column_name_z => $column_01_data, # first column data
        column_name_y => $column_02_data, # second column data
        column_name_x => $column_03_data, # third column data
    ]

then the column data is added to the data frame in the order that the pairs
appear in the C<ArrayRef>.

=item * columns => HashRef $columns_hash

    $columns_hash = {
        column_name_z => $column_03_data, # third column data
        column_name_y => $column_02_data, # second column data
        column_name_x => $column_01_data, # first column data
    }

then the column data is added to the data frame by the order of the keys in the
C<HashRef> (sorted with a stringwise C<cmp>).

=back

=head2 string

    string() # returns Str

Returns a string representation of the C<Data::Frame>.

=head2 number_of_columns

    number_of_columns() # returns Int

Returns the count of the number of columns in the C<Data::Frame>.

=head2 number_of_rows

    number_of_rows() # returns Int

Returns the count of the number of rows in the C<Data::Frame>.

=head2 nth_columm

    number_of_rows(Int $n) # returns a column

Returns column number C<$n>. Supports negative indices (e.g., $n = -1 returns
the last column).

=head2 column_names

    column_names() # returns an ArrayRef

    column_names( @new_column_names ) # returns an ArrayRef

Returns an C<ArrayRef> of the names of the columns.

If passed a list of arguments C<@new_column_names>, then the columns will be
renamed to the elements of C<@new_column_names>. The length of the argument
must match the number of columns in the C<Data::Frame>.

=head2 row_names

    row_names() # returns a PDL

    row_names( Array @new_row_names ) # returns a PDL

    row_names( ArrayRef $new_row_names ) # returns a PDL

    row_names( PDL $new_row_names ) # returns a PDL

Returns an C<ArrayRef> of the names of the columns.

If passed a argument, then the rows will be renamed. The length of the argument
must match the number of rows in the C<Data::Frame>.

=head2 column

    column( Str $column_name )

Returns the column with the name C<$column_name>.

=head2 add_columns

    add_columns( Array @column_pairlist )

Adds all the columns in C<@column_pairlist> to the C<Data::Frame>.

=head2 add_column

    add_column(Str $name, $data)

Adds a single column to the C<Data::Frame> with the name C<$name> and data
C<$data>.

=head2 select_rows

    select_rows( Array @which )

    select_rows( ArrayRef $which )

    select_rows( PDL $which )

The argument C<$which> is a vector of indices. C<select_rows> returns a new
C<Data::Frame> that contains rows that match the indices in the vector
C<$which>.

This C<Data::Frame> supports PDL's data flow, meaning that changes to the
values in the child data frame columns will appear in the parent data frame.

If no indices are given, a C<Data::Frame> with no rows is returned.

=head1 SEE ALSO

=over 4

=item * L<R manual: data.frame|https://stat.ethz.ch/R-manual/R-devel/library/base/html/data.frame.html>.

=item * L<Statistics::NiceR>

=item * L<PDL>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
