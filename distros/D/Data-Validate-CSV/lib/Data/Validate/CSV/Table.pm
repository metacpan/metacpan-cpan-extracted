use v5.12;
use strict;
use warnings;

package Data::Validate::CSV::Table;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo;
use PerlX::Maybe;
use Data::Validate::CSV::Types -types;
use Types::Common::Numeric qw(PositiveOrZeroInt);
use Types::Path::Tiny qw(Path);
use namespace::autoclean;

has columns => (
	is        => 'rwp',
	isa       => ArrayRef[Column],
	init_arg  => undef,
);

has has_header => (
	is        => 'lazy',
	isa       => Bool,
	coerce    => 1,
	builder   => sub { 0 },
);

has skip_rows => (
	is        => 'ro',
	isa       => PositiveOrZeroInt,
	builder   => sub { 0 },
);

has skip_rows_after_header => (
	is        => 'ro',
	isa       => PositiveOrZeroInt,
	builder   => sub { 0 },
);

has input => (
	is        => 'ro',
	isa       => FileHandle->plus_coercions(
		Path,        q{ $_->openr_utf8 },
		ScalarRef,   q{ do { require IO::String; IO::String->new($$_) } },
	),
	coerce    => 1,
	required  => 1,
);

has schema => (
	is        => 'ro',
	isa       => Schema,
	coerce    => 1,
);

has reader => (
	is        => 'lazy',
	isa       => CodeRef,
);

my $implementation;
sub _build_reader {
	my $self = shift;
	$implementation ||= eval { require Text::CSV_XS; 'Text::CSV_XS' };
	$implementation ||= do   { require Text::CSV;    'Text::CSV' };
	my $csv = $implementation->new({
		allow_whitespace   => 1,
		sep_char           => q{,},
	});
	sub { $csv->getline($_[0]) };
}

has _done_init => (
	is        => 'rw',
	isa       => Bool,
	init_arg  => undef,
	default   => !!0,
);

has row_count => (
	is        => 'rwp',
	isa       => PositiveOrZeroInt,
	default   => 0,
);

has column_class => (
	is        => 'ro',
	isa       => ClassName,
	default   => Column->class,
);

has row_class => (
	is        => 'ro',
	isa       => ClassName,
	default   => Row->class,
);

has _pkey_seen => (
	is        => 'ro',
	isa       => HashRef,
	default   => sub { +{} },
);

sub get_row {
	my $self = shift;
	$self->_init unless $self->_done_init;
	
	my $raw = $self->reader->($self->input);
	return unless $raw;
	
	my $n = $self->row_count;
	$self->_set_row_count(++$n);
	
	my $row = $self->row_class->new(
		columns                   => $self->columns,
		column_class              => $self->column_class,
		raw_values                => $raw,
		row_number                => $n,
		maybe primary_key_columns => $self->schema->primary_key,
	);
	
	if ($row->primary_key_columns) {
		my $str = $row->key_string;
		if (my $seen = $self->_pkey_seen->{$str}) {
			$row->report_error("Already seen primary key on row $seen");
		}
		else {
			$self->_pkey_seen->{$str} = $n;
		}
	}
	
	return $row;
}

sub _init {
	my $self = shift;
	return if $self->_done_init;
	for (my $i = 0; $i < $self->skip_rows; ++$i) {
		$self->reader->();
	}
	if ($self->has_header) {
		my $columns = $self->schema->clone_columns;
		my $header  = $self->reader->($self->input);
		if ($header) {
			for my $i (0 .. $#$header) {
				($columns->[$i] ||= $self->column_class->new)->maybe_set_name($header->[$i]);
			}
			for (my $i = 0; $i < $self->skip_rows_after_header; ++$i) {
				$self->reader->($self->input);
			}
		}
		$self->_set_columns($columns);
	}
	else {
		$self->_set_columns($self->schema->clone_columns);
	}
	$self->_done_init(1);
}

sub all_rows {
	my $self = shift;
	my @rows;
	while (my $row = $self->get_row) {
		push @rows, $row;
	}
	return @rows;
}

1;
