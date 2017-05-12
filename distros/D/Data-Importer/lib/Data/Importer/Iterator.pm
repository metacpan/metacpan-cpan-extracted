#
# This file is part of Data-Importer
#
# This software is copyright (c) 2014 by Kaare Rasmussen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Data::Importer::Iterator;
$Data::Importer::Iterator::VERSION = '0.006';
use 5.010;
use namespace::autoclean;
use Moose;

=head1 Description

Base class for handling the import of a file

Currently, there are iterators for L<CSV|Data::Importer::Iterator::Csv>, L<ODS|Data::Importer::Iterator::Ods>, and L<XLS|Data::Importer::Iterator::Xls>, 

=head1 ATTRIBUTES

=head2 lineno

The line counter

=cut

has 'lineno' => (
	is => 'ro',
	isa => 'Num',
	traits => ['Counter'],
	default => 0,
	handles => {
		inc_lineno => 'inc',
		reset_lineno => 'reset',
	},
);

=head2 file_name

The name of the import file

=cut

has file_name => (
	is => 'ro',
	isa => 'Str',
);

=head2 mandatory

Required input columns

=cut

has 'mandatory' => (
	is => 'ro',
	isa => 'ArrayRef',
);

=head2 optional

Required input columns

=cut

has 'optional' => (
	is => 'ro',
	isa => 'ArrayRef',
);

=head2 encoding

The encoding of the spreadsheet

=cut

has encoding => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_encoding',
);

=head1 METHODS

=head2 next

Return the next row of data from the file

=cut

sub next {
	return 'should be sub classed';
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
