package Data::Package::CSV;

=pod

=head1 NAME

Data::Package::CSV - A Data::Package class for CSV data using Parse::CSV

=head1 DESCRIPTION

The B<Data::Package::CSV> package provides a subclass of
L<Data::Package::File> that provides data from a CSV file by integrating
with L<Parse::CSV>.

=head1 METHODS

=cut

use 5.005;
use strict;
use base 'Data::Package::File';
use Parse::CSV     ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}

sub import {
	return 1 if $_[0] eq __PACKAGE__;
	return shift->SUPER::import(@_);
}





#####################################################################
# Data::Package::CSV Methods

=pod

=head2 csv_options

The B<cvs_options> method is the most direct method, with full control
over the creation of the L<Parse::CSV> object. If a fully compliant options
hash is returned (as a list) then no other methods need to be defined.

The list returned by the B<cvs_options> method will be passed directly to
the L<Parse::CSV> constructor. Read the documentation for L<Parse::CSV> for
more details on what you should return to match your data.

By default, the null list is return, specifying entirely default options
to the L<Parse::CSV> constructor (array mode) and not specifying any filters
or parsing variations.

If it list that is returned does not have either a data source (either a
C<handle> param or C<file> param) then the C<file> method for the parent
class will be called to locate a file.

=cut

sub csv_options {
	return ();
}





#####################################################################
# Data::Package Methods

sub _provides {
	my @provides = shift->SUPER::_provides(@_);
	return ( 'Parse::CSV', @provides );
}

sub __as_Parse_CSV {
	my $class = ref($_[0]) || $_[0];

	# Get the main options
	my %options = $class->csv_options;
	unless ( $options{handle} or $options{file} ) {
		delete $options{file};
		delete $options{handle};

		# Locate the data
		my $file = $class->file;
		if ( $file ) {
			$options{file} = $class->file;
			delete $options{handle};
		} else {
			die "No CSV file found for $class";		
		}
	}

	# Create the parser object
	my $parse_csv = Parse::CSV->new( %options );
	unless ( $parse_csv ) {
		die "Failed to create Parse::CSV object for $class";
	}

	return $parse_csv;
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Package-CSV>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
