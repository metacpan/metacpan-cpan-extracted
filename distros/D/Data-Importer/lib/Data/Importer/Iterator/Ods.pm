#
# This file is part of Data-Importer
#
# This software is copyright (c) 2014 by Kaare Rasmussen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Data::Importer::Iterator::Ods;
$Data::Importer::Iterator::Ods::VERSION = '0.006';
use 5.010;
use namespace::autoclean;
use Moose;
use Spreadsheet::ReadSXC qw/read_sxc/;

extends 'Data::Importer::Iterator';

=head1 Description

Subclass for handling the import of an ods file

=head1 ATTRIBUTES

=head2 ods

The ods object

=cut

has 'ods' => (
	is => 'ro',
	lazy_build => 1,
);

=head2 sheet

The sheet name or number

=cut

has sheet => (
	is => 'ro',
	isa => 'Int',
	default => 0,
);

=head2 options

Options to be passed to the Spreadsheet::ReadSXC constructor

=cut

has 'options' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub {
		return {
			OrderBySheet => 1,
		};
	},
	lazy => 1,
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

=head2 _build_ods

The lazy builder for the ods object

=cut

sub _build_ods {
	my $self = shift;
	my $worksheets_ref = read_sxc($self->file_name, $self->options);
	my $ods = $$worksheets_ref[0]{data};
	return $ods;
}

=head2 next

Return the next row of data from the file

=cut

sub next {
	my $self = shift;
	my $ods = $self->ods;
	# Use the first row as column names:
	if (!$self->has_column_names) {
		my @fieldnames = map {my $header = lc $_; $header =~ tr/ /_/; $header} @{ $ods->[$self->lineno] };
		die "Only one column detected, please use comma ',' to separate data." if @fieldnames < 2;
		my %fieldnames = map {$_ => 1} @fieldnames;
		if (my @missing = grep {!$fieldnames{$_} } @{ $self->mandatory }) {
			die 'Column(s) required, but not found:' . join ', ', @missing;
		}

		$self->column_names(\@fieldnames);
	}
	my $columns = $self->column_names;
	$self->inc_lineno;
	my @cells = @{ $ods->[$self->lineno] || [] };
	return unless grep { $_ } @cells;

	my $colno = 0;
    return { map { $columns->[$colno++] => $_ } @cells };
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
