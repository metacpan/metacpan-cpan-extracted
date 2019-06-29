package Data::TableReader::Decoder::XLSX;
use Moo 2;
use Carp;
use Try::Tiny;
extends 'Data::TableReader::Decoder::Spreadsheet';

our @xlsx_probe_modules= qw( Spreadsheet::ParseXLSX Spreadsheet::XLSX );
our $default_xlsx_module;
sub default_xlsx_module {
	$default_xlsx_module ||=
		Data::TableReader::Decoder::_first_sufficient_module('XLSX parser', \@xlsx_probe_modules);
}

# ABSTRACT: Access sheets/rows of a modern Microsoft Excel workbook
our $VERSION = '0.011'; # VERSION


sub _build_workbook {
	my $self= shift;
	
	my $wbook;
	my $f= $self->file_handle;
	if (ref $f and ref($f)->can('worksheets')) {
		$wbook= $f;
	} else {
		my $class= $self->default_xlsx_module;
		# Spreadsheet::XLSX has an incompatible constructor
		if ($class->isa('Spreadsheet::XLSX')) {
			$wbook= $class->new($f);
		} else {
			$wbook= $class->new->parse($f, $self->xls_formatter);
		}
	}
	defined $wbook or croak "Can't parse file '".$self->file_name."'";
	return $wbook;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableReader::Decoder::XLSX - Access sheets/rows of a modern Microsoft Excel workbook

=head1 VERSION

version 0.011

=head1 DESCRIPTION

See L<Data::TableReader::Decoder::Spreadsheet>.
This subclass simply parses the input using an instance of L<Spreadsheet::ParseXLSX>.

=head1 CLASS METHODS

=head2 default_xlsx_module

Initializes C<@Data::TableReader::Decoder::XLSX::default_xlsx_module> to the first
available module in the list of C<@Data::TableReader::Decoder::XLSX::xlsx_probe_modules>
and returns the cached value every time afterward.

Those variables can be modified as needed, if you have other XLSX modules available.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
