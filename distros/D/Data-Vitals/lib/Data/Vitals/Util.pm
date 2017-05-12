package Data::Vitals::Util;

=pod

=head1 NAME

Data::Vitals::Util - Utility methods for the Perl "Vital Statistics" Library

=head1 DESCRIPTION

Data::Vitals::Util defines a set of functions that are used in various
places within the L<Data::Vitals> classes.

All functions are importable using the standard Exporter mechanism

  use Data::Vitals::Util 'cm2inch';

=head1 FUNCTIONS

=cut

use strict;
use Exporter ();

use vars qw{$VERSION @ISA @EXPORT_OK};
BEGIN {
	$VERSION   = '0.05';
	@ISA       = 'Exporter';
	@EXPORT_OK = qw{cm2inch inch2cm};
}





# A pair of cm <-> inch conversion functions.
# These are specialised DWIM converters for body measurements.
# A key requirement for the integrity of the data is that the conversion
# path inch->cm->inch is always guarenteed to be the same value.
# The same is NOT true for cm->inch->cm, but since we always store and
# calculate in cm this should not be a problem.

=pod

=head2 cm2inch $cm

The C<cm2inch> function is a specialised method for converting a centimetre
measurement to inchs. It converts using the standard 2.54004 multiplier,
but rounds down to the half-inch.

The algorithm used is specifically designed so that, when used as a pair
with the inch2cm method, any value that C<cm2inch(inch2cm($x)) == $x> is
always true, although it may not be true of the reverse.

It takes as argument a number without any 'cm' indicator, and returns the
number of inches as a similar plain number.

=cut

sub cm2inch {
	my $cm = 0 + shift;

	# We round down slightly, but it should be less than half
	# an inch and so not a big issue from a fitting perspective.
	my $inch = int($cm / 2.54004);

	# Support half-inches
	my $part = ($cm / 2.54004) - $inch;
	$inch += 0.5 if $part >= 0.5;

	$inch;
}

=pod

=head2 inch2cm $cm

The C<inch2cm> function is a specialised method for converting an inch
measurement to centimetres. It converts using the standard 2.54004
multiplier, but rounds up to the nearest centimetre.

The algorithm used is specifically designed so that, when used as a pair
with the cm2inch method, any value that C<cm2inch(inch2cm($x)) == $x> is
always true, although it may not be true of the reverse.

It takes as argument a number without any 'inch' indicator, and returns the
number of centimetres as a similar plain number.

=cut

sub inch2cm {
	my $inch = 0 + shift;

	# We round up slightly, but it should be less than a cm
	# and so not a big issue from a fitting perspective.
	my $cm = $inch * 2.54004;
	if ( $cm - int($cm) ) {
		$cm = int($cm) + 1;
	}

	$cm;
}

1;

=pod

=head1 SUPPORT

Bugs should always be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Vitals>

For other issues, contact the maintainer.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKNOWLEGEMENTS

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution.

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
