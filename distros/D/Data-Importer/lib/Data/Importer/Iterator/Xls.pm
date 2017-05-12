#
# This file is part of Data-Importer
#
# This software is copyright (c) 2014 by Kaare Rasmussen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Data::Importer::Iterator::Xls;
$Data::Importer::Iterator::Xls::VERSION = '0.006';
use 5.010;
use namespace::autoclean;
use Moose;
use Encode qw(encode);
use Spreadsheet::ParseExcel;

extends 'Data::Importer::Iterator';

=head1 Description

Subclass for handling the import of an excel file

=head1 ATTRIBUTES

=head2 excel

The excel object

=cut

has 'excel' => (
	is => 'ro',
	lazy_build => 1,
);

=head2 sheet

The sheet name or number

=cut

has sheet => (
	is => 'ro',
	isa => 'Str',
	default => 0,
);

=head1 "PRIVATE" ATTRIBUTES

=head2 column_names

The column names

=cut

has column_names => (
	is => 'rw',
	isa => 'ArrayRef',
	predicate => 'has_column_names',
);

=head1 METHODS

=head2 _build_excel

The lazy builder for the excel object

=cut

sub _build_excel {
	my $self = shift;
	my $table = Spreadsheet::ParseExcel->new()
		->parse($self->file_name)
		->worksheet($self->sheet);
	return $table;
}

=head2 next

Return the next row of data from the file

=cut

sub next {
	my $self = shift;
	my $xls = $self->excel;
	state $rc = [$xls->row_range];
	state $cc = [$xls->col_range];
	# Use the first row as column names:
	if (!$self->has_column_names) {
		my @fieldnames = map {my $header = lc $_; $header =~ tr/ /_/; $header} grep {$_} $self->_get_row_values($xls, @$cc);
		die "Only one column detected, please use comma ',' to separate data." if @fieldnames < 2;
		my %fieldnames = map {$_ => 1} @fieldnames;
		if (my @missing = grep {!$fieldnames{$_} } @{ $self->mandatory }) {
			die 'Column(s) required, but not found:' . join ', ', @missing;
		}

		$self->column_names(\@fieldnames);
		$cc->[1] = scalar @fieldnames;
	}
	$self->inc_lineno;
	return $self->_get_row($xls, @$cc);
}

sub _get_row_values {
	my ($self, $xls, $from, $to) = @_;
	my @cells;
	push @cells, $xls->get_cell($self->lineno, $_)->value for $from..$to;
	return @cells;
}

sub _get_row {
	my ($self, $xls, $from, $to) = @_;
	my $colnames = $self->column_names;
	my %cells;
	my $cells;
	for my $colno ($from..$to) {
		my $colname = $colnames->[$colno - $from] // '';
		if (my $cell = $xls->get_cell($self->lineno, $colno)) {
			my $value = $cell->value;
			if ($cell->encoding == 2) {
				$value = encode('utf-16BE', $cell->value);
			} elsif ($self->has_encoding) {
				$value = encode($self->encoding, $value);
			}
			$cells{ $colname } = $value;
			$cells++;
		} else {
			$cells{ $colname } = undef;
		}
	}
	return $cells ? \%cells : undef;
}

__PACKAGE__->meta->make_immutable;

#
# This file is part of Data-Importer
#
# This software is copyright (c) 2014 by Kaare Rasmussen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__
