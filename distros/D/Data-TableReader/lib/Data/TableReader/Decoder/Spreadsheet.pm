package Data::TableReader::Decoder::Spreadsheet;
use Moo 2;
use Carp 'croak';
use IO::Handle;

extends 'Data::TableReader::Decoder';

# ABSTRACT: Base class for implementing spreadsheet decoders
our $VERSION = '0.011'; # VERSION


has workbook => ( is => 'lazy' );
has sheet => ( is => 'ro' );
has xls_formatter => ( is => 'rw' );

# Arrayref of all sheets we can search
has _sheets => ( is => 'lazy' );

sub _build__sheets {
	my $self= shift;

	# If we have ->sheet and it is a worksheet object, then no need to do anything else
	if ($self->sheet && ref($self->sheet) && ref($self->sheet)->can('get_cell')) {
		return [ $self->sheet ];
	}

	# Else we need to scan sheets from the excel file.  Make sure we have the file
	my @sheets= $self->workbook->worksheets;
	@sheets or croak "No worksheets in file?";
	if (defined $self->sheet) {
		if (ref($self->sheet) eq 'Regexp') {
			@sheets= grep { $_->get_name =~ $self->sheet } @sheets;
		} elsif (ref($self->sheet) eq 'CODE') {
			@sheets= grep { $self->sheet->($_) } @sheets;
		} elsif (!ref $self->sheet) {
			@sheets= grep { $_->get_name eq $self->sheet } @sheets;
		} else {
			croak "Unknown type of sheet specification: ".$self->sheet;
		}
	}

	return \@sheets;
}

sub _oo_rowmax_fix {    # openoffice saves bogus rowmax, try and fix
    my ($s, $rowmax)= @_;
    my $final_row_max= ($s and ref $s->{Cells} eq "ARRAY" and $#{$s->{Cells}} < $rowmax)    #
      ? $#{$s->{Cells}} : $rowmax;
    return $final_row_max;
}

sub iterator {
	my $self= shift;
	my $sheets= $self->_sheets;
	my $sheet= $sheets->[0];
	my ($colmin, $colmax)= $sheet? $sheet->col_range() : (0,-1);
	my ($rowmin, $rowmax)= $sheet? $sheet->row_range() : (0,-1);
	$rowmax= _oo_rowmax_fix $sheet, $rowmax;
	my $row= $rowmin-1;
	Data::TableReader::Decoder::Spreadsheet::_Iter->new(
		sub {
			my $slice= shift;
			return undef unless $row < $rowmax;
			++$row;
			my $x;
			if ($slice) {
				return [ map {
					$x= ($x= $sheet->get_cell($row, $_)) && $x->value;
					defined $x? $x : ''
				} @$slice ];
			} else {
				return [ map {
					$x= ($x= $sheet->get_cell($row, $_)) && $x->value;
					defined $x? $x : ''
				} 0 .. $colmax ];
			}
		},
		{
			sheets => $sheets,
			sheet_idx => 0,
			sheet_ref => \$sheet,
			row_ref => \$row,
			colmax_ref => \$colmax,
			rowmax_ref => \$rowmax,
			origin => [ $sheet, $row ],
		}
	);
}

# If you need to subclass this iterator, don't.  Just implement your own.
# i.e. I'm not declaring this implementation stable, yet.
use Data::TableReader::Iterator;
BEGIN { @Data::TableReader::Decoder::Spreadsheet::_Iter::ISA= ('Data::TableReader::Iterator'); }

sub Data::TableReader::Decoder::Spreadsheet::_Iter::position {
	my $f= shift->_fields;
	'row '.${ $f->{row_ref} };
}
   
sub Data::TableReader::Decoder::Spreadsheet::_Iter::progress {
	my $f= shift->_fields;
	return ${ $f->{row_ref} } / (${ $f->{rowmax_ref} } || 1);
}

sub Data::TableReader::Decoder::Spreadsheet::_Iter::tell {
	my $f= shift->_fields;
	return [ $f->{sheet_idx}, ${$f->{row_ref}} ];
}

sub Data::TableReader::Decoder::Spreadsheet::_Iter::seek {
	my ($self, $to)= @_;
	my $f= $self->_fields;
	$to ||= $f->{origin};
	my ($sheet_idx, $row)= @$to;
	my $sheet= $f->{sheets}[$sheet_idx];
	my ($colmin, $colmax)= $sheet? $sheet->col_range() : (0,-1);
	my ($rowmin, $rowmax)= $sheet? $sheet->row_range() : (0,-1);
	$rowmax= _oo_rowmax_fix $sheet, $rowmax;
	$row= $rowmin-1 unless defined $row;
	$f->{sheet_idx}= $sheet_idx;
	${$f->{sheet_ref}}= $sheet;
	${$f->{row_ref}}= $row;
	${$f->{colmax_ref}}= $colmax;
	${$f->{rowmax_ref}}= $rowmax;
	1;
}

sub Data::TableReader::Decoder::Spreadsheet::_Iter::next_dataset {
	my $self= shift;
	my $f= $self->_fields;
	return defined $f->{sheets}[ $f->{sheet_idx}+1 ]
		&& $self->seek([ $f->{sheet_idx}+1 ]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableReader::Decoder::Spreadsheet - Base class for implementing spreadsheet decoders

=head1 VERSION

version 0.011

=head1 DESCRIPTION

This is a base class for any file format that exposes a spreadsheet API
compatible with L<Spreadsheet::ParseExcel>.

=head1 ATTRIBUTES

See attributes from parent class: L<Data::TableReader::Decoder>.

=head2 workbook

This is an instance of L<Spreadsheet::ParseExcel>, L<Spreadsheet::ParseXLSX>,
or L<Spreadsheet::XLSX> (which all happen to have the same API).  Subclasses can
lazy-build this from the C<file_handle>.

=head2 sheet

This is either a sheet name, a regex for matching a sheet name, or a parser's
worksheet object.  It is also optional; if not set, all sheets will be iterated.

=head2 xls_formatter

An optional object that is passed to Excel parsers L<Spreadsheet::ParseXLSX> and
L<Spreadsheet::ParseExcel>. It governs how raw data in cells is formatted into
values depending on the type of the cell. The parsers create one of their own if
none is provided, usually L<Spreadsheet::ParseExcel::FmtDefault>.

Note that it does not work for Spreadsheet::XLSX, which hardcodes the formatter
as Spreadsheet::XLSX::Fmt2007.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
