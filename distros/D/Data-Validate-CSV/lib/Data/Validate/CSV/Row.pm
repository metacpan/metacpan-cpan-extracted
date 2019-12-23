use v5.12;
use strict;
use warnings;

package Data::Validate::CSV::Row;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo;
use Data::Validate::CSV::Types -types;
use Types::Common::Numeric qw( PositiveOrZeroInt );
use List::Util qw(max);
use namespace::autoclean;

use overload '@{}' => sub { shift->values }, fallback => 1;

has columns => (
	is        => 'ro',
	isa       => ArrayRef[Column],
	coerce    => !!1,
);

has raw_values => (
	is        => 'ro',
	isa       => ArrayRef[Str],
	required  => !!1,
);

has values => (
	is        => 'lazy',
	isa       => ArrayRef[ Str | ArrayRef[Str] ],
);

has _reported_errors => (
	is        => 'lazy',
	builder   => sub { [] },
);

sub _build_values {
	my $self = shift;
	[ map $_->value, @{ $self->cells } ];
}

has cells => (
	is        => 'lazy',
	isa       => ArrayRef[Cell],
);

has row_number => (
	is        => 'ro',
	isa       => PositiveOrZeroInt,
);

has primary_key_columns => (
	is        => 'ro',
	isa       => ArrayRef->of(Str)->plus_coercions(Str, '[$_]'),
	coerce    => !!1,
	predicate => !!1,
);

has key_string => (
	is        => 'lazy',
	isa       => Str,
);

has single_value_cell_class => (
	is        => 'ro',
	isa       => ClassName,
	default   => SingleValueCell->class,
);

has multi_value_cell_class => (
	is        => 'ro',
	isa       => ClassName,
	default   => MultiValueCell->class,
);

has column_class => (
	is        => 'ro',
	isa       => ClassName,
	default   => Column->class,
);

sub _build_cells {
	my $self = shift;
	my $raws = $self->raw_values;
	my $cols = $self->columns;
	my @cells;
	for my $i (0 .. $#$raws) {
		$cols->[$i] ||= $self->column_class->new;
		my $class = $cols->[$i]->has_separator
			? $self->multi_value_cell_class
			: $self->single_value_cell_class;
		push @cells, $class->new(
			raw_value  => $raws->[$i],
			row_number => $self->row_number,
			col_number => $i + 1,
			row        => $self,
			col        => $cols->[$i],
		);
	}
	\@cells;
}

sub _build_key_string {
	my $self = shift;
	return '' unless $self->has_primary_key_columns;
	my %hash;
	$hash{$_->col->name} = $_
		for grep $_->col->has_name, @{ $self->cells };
	my @cells = map $hash{$_}, @{$self->primary_key_columns};
	join ',', map $_->_chunk_for_key_string, @cells;
}

sub errors {
	my $self = shift;
	[
		@{ $self->_reported_errors },
		map @{$_->errors}, @{$self->cells},
	];
}

sub report_error {
	my $self = shift;
	push @{$self->_reported_errors}, @_;
}

sub get {
	my $self = shift;
	my ($name) = @_;
	my ($cell) = grep { $_->col->has_name and $_->col->name eq $name } @{$self->cells};
	$cell;
}

1;
