package Data::Vitals::Circumference;

=pod

=head1 NAME

Data::Vitals::Circumference - A measurement of the circumference around part
of the human body.

=head1 DESCRIPTION

A significant number of measurements in the L<Data::Vitals> package relate to
measurements of the circumference of part of the human body.

Some examples include the L<Chest|Data::Vitals::Chest>,
L<Waist|Data::Vitals::Waist> and L<Hips|Data::Vitals::Hips> measurements.

These measurements are generally recorded in the same format, either as a
number of inches or as a number of centimetres.

The Data::Vitals::Circumference package provides a base class for the
family of circumference measurements, and can also be used directly to take
an arbitrary circumference measurement not defined in the main DatA::Vitals
package.

=head2 The "Circumference String"

Because this is such a general package, great effort has been taken to avoid
assumptions that might lead to incorrect measurements. Measurements in both
inches and cms are very widespread, and in order to support them both we do
not accept raw numbers as input to the contructors.

Any "Circumference String" B<must> provide an indication of the unit. We try
to find this a flexibly as possible.

The following shows samples for the formats accepted. 

  Metric measurements
  30cm        Default form
  86.5cm      Halves (and only halves) are also allowed
  85c         Shorthand form (or you accidentally missed the m)
  85cms       Plural form
  85CM        Case insensitive
  85 cm       Whitespace is ignored
  
  Imperial Measurements
  30"         Default form
  30.5"       Halves (and only halves) are also allowed
  30i         Various fragments of "inches"
  30in        Various fragments of "inches"
  30inc       Various fragments of "inches"
  30inch      Various fragments of "inches"
  30inche     Various fragments of "inches"
  30inches    Various fragments of "inches"
  30inchs     Bad spelling
  30INCHES    Case insensitive
  30 inches   Case insensitive
  30 "        Whitespace is ignored

=head2 Storage and Conversion

Regardless of the method that the value is entered, all values are stored
internally in centimetres. The default string form of all measurements is
also given in centimetres.

This is a specific design decision, as there is a long term world trend
towards increased metrification. Many countries such as Germany use metric
values even for the "common" understanding of things and would be
hard-pressed to tell you their height in feet and inches.

However, to support those still dealing in inches we ensure that any
value initially entered in inches (including optional halves), stored as
cms, and returned to inches for presentation will ALWAYS return the
original number of inches, including halves.

The conversion functions in L<Data::Vitals::Util> are heavily tested for
every possible value in the range to ensure that this is the case.

=head1 METHODS

=cut

use strict;
use Data::Vitals::Util ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.05';
}

use overload 'bool' => sub () { 1 };
use overload '""'   => 'as_string';





#####################################################################
# Constructor

=pod

=head2 new $circumference

The C<new> constructor takes a circumference string and returns a new
object representing the measurement, or C<undef> if there is a problem
with the value provided.

Currently, there is no explanation of the reason why a value is rejected.
Any used may need to just be presented with an "Invalid Value" message.

In future, a mechanism to access error messages following an error will
be added.

=cut

sub new {
	my $class = ref $_[0] || $_[0];
	my $value = defined $_[1] ? lc $_[1] : return undef;
	$value =~ s/\s+//g;

	# Metric "123cm" or "123.5cm" or "123c"
	if ( $value =~ /^(\d+(?:\.5)?)(?:c|cm|cms)$/ ) {
		my $cm = $1 + 0;
		unless ( $cm > 10 and $cm < 400 ) {
			# Impossibly out of range
			return undef;
		}
		return bless { value => $cm }, $class;
	}

	# Imperial '30"' or '30.5"' or '30i' or '30inchs'
	if ( $value =~ /^(1?\d{1,2}(?:\.5)?)(?:\"|i|in|inc|inch|inchs|inches)$/ ) {
		my $inch = $1 + 0;
		unless ( $inch > 3 and $inch < 120 ) {
			# Impossibly out or range
			return undef;
		}
		my $cm = Data::Vitals::Util::inch2cm($inch) or return undef;
		return bless { value => $cm }, $class;
	}

	# Anything else
	undef;
}

###------------------------------------------------------------------

=pod

=head2 as_string

The C<as_string> method returns the generic string form of the measurement.

This is also the method called during overloaded stringification. By
default, this returns the metric form, which is in centimetres.

=cut

# Generic string form, which is currently set in metric.
# Normally, given the American bias in programming, I would have done
# this as inches. However there is a long term trend towards
# metrification, and from a support issue it is better to be a bit more
# aggressive and use standard units by default earlier, rather than be
# stuck with a default string form that nobody uses in future years.
sub as_string { shift->as_metric }

###------------------------------------------------------------------

=pod

=head2 as_metric

The C<as_metric> method returns the metric form of the measurement, which
for circumference measurements is always in centimetres.

=cut

sub as_metric { shift->as_cms }

###------------------------------------------------------------------

=pod

=head2 as_imperial

The C<as_imperial> method returns the imperial form of the measurement,
which for circumference measurements is in raw inches (with no conversion
to feet and inches)

=cut

sub as_imperial { shift->as_inches }

###------------------------------------------------------------------

=pod

=head2 as_cms

The C<as_cms> method explicitly returns the measurement in centimetres.

The format of the string returned is similar to C<38cm>.

=cut

sub as_cms { $_[0]->{value} . 'cm' }

###------------------------------------------------------------------

=pod

=head2 as_inches

The C<as_inches> method explicitly returns the measurement in inches.

Unlike L<Height|Data::Vitals::Height>, it is B<not> converted to feet,
and is shown just as raw inches.

The format of the string returned is similar to C<38">

=cut

sub as_inches { Data::Vitals::Util::cm2inch($_[0]->{value}) . '"' }

###------------------------------------------------------------------

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
