package Data::TableReader::Decoder::XLSX;
$Data::TableReader::Decoder::XLSX::VERSION = '0.005';
use Moo 2;
use Carp;
use Try::Tiny;
extends 'Data::TableReader::Decoder::Spreadsheet';

our @xlsx_probe_modules= qw( Spreadsheet::ParseXLSX Spreadsheet::XLSX );
our $default_xlsx_module;
sub default_xlsx_module {
	$default_xlsx_module ||= do {
		eval "require $_" && return $_ for @xlsx_probe_modules;
		croak "No XLSX parser available; install one of: ".join(', ', @xlsx_probe_modules);
	};
}

# ABSTRACT: Access sheets/rows of a modern Microsoft Excel workbook


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
			$wbook= $class->new->parse($f);
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

version 0.005

=head1 DESCRIPTION

See L<Data::TableReader::Decoder::Spreadsheet>.
This subclass simply parses the input using an instance of L<Spreadsheet::ParseXLSX>.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
