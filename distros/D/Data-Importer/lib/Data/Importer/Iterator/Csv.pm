#
# This file is part of Data-Importer
#
# This software is copyright (c) 2014 by Kaare Rasmussen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Data::Importer::Iterator::Csv;
$Data::Importer::Iterator::Csv::VERSION = '0.006';
use 5.010;
use namespace::autoclean;
use Moose;
use Text::CSV;
use Encode qw/encode/;

extends 'Data::Importer::Iterator';

=head1 Description

Subclass for handling the import of a csv file

=head1 ATTRIBUTES

=head2 csv

The csv object

=cut

has 'csv' => (
	is => 'ro',
	lazy_build => 1,
);

=head1 "PRIVATE" ATTRIBUTES

=head2 file

The import file

=cut

has 'file' => (
	is => 'ro',
	lazy_build => 1,
);

=head1 METHODS

=head2 _build_csv

The lazy builder for the csv object

=cut

sub _build_csv {
	my $self = shift;
	my $csv = Text::CSV->new ({ binary => 1, eol => $/ });
	return $csv;
}

=head2 _build_file

The lazy builder for the file

The base class opens a file as UTF-8 and returns it.

=cut

sub _build_file {
	my $self = shift;
	my $filename = $self->file_name;
	my $attr = $self->has_encoding ? ':encoding(' . $self->encoding . ')' : '';
	open(my $file, "<$attr", $filename) or die "$filename: $!";

	return $file;
}

=head2 next

Return the next row of data from the file

=cut

sub next {
	my $self = shift;
	my $file = $self->file;
	my $csv = $self->csv;
	# Use the first row as column names:
	if (!$csv->column_names) {
		my $row = $csv->getline($file);
		my @fieldnames = map {my $header = lc $_; $header =~ tr/ /_/; $header} @$row;
		die "Only one column detected, please use comma ',' to separate data." if @fieldnames < 2;
		my %fieldnames = map {$_ => 1} @fieldnames;
		if (my @missing = grep {!$fieldnames{$_} } @{ $self->mandatory }) {
			die 'Column(s) required, but not found:' . join ', ', @missing;
		}

		$csv->column_names(@fieldnames);
	}
	$self->inc_lineno;
	return $csv->getline_hr($file);
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
