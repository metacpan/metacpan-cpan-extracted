package Data::Vitals::Height;

=pod

=head1 NAME

Data::Vitals::Circumference - A measurement of the circumference around part
of the human body.

=head1 DESCRIPTION

The Data::Vitals::Height package provides an implementation of the height of
a person.

This can be taken by standard backwards against wall or other vertical
surface with your heels, seat, shoulders, and head touching the surface.
You should be standing straight with your head in a horizontal position.

A rule is placed horizontally and gently pressed down into the hair, so
that it presses on the skull. The point at which the rule contacts the wall
is noted, and then measured down to the floor.

=head2 The "Height String"

For height, measurements in both "feet and inches" and centimetres are
widespread, and we try to support them both where the intent is obvious.

Any imperial measurement MUST contain two parts, and indicate B<at least>
the "feet" indicator. The one case of input without the unit specificier we
allow is any single two or three digit number, which is taken to mean
centimetres.

For metric, the supported input range is 30cm - 300cm. For imperial, it is
1'0" - 8'11". This range ignores very small babies but is slightly larger than
the world record at the top end, and so is fairly all-encompassing.

The ability to customise these legal ranges will be added at a later time.

The following shows samples for the formats accepted. 

  Metric measurements
  180cm       Default form
  180.5cm     Halves (and only halves) are allowed
  180         Raw three digit number
  95          Raw two digit number
  180c        Shorthand (or missed the m)
  180cms      Plural form
  180CM       Case insensitive
  180 cm      Whitespace between the type is ignored
  
  Imperial Measurements
  5'10"       Default form
  5'10        If a 'feet' indicator is given, inches is implied
  5' 10       Whitespace is ignored
  5'10        Various inch indicators
  5'10i       Various inch indicators
  5'10in      Various inch indicators
  5'10inc     Various inch indicators
  5'10inch    Various inch indicators
  5'10inche   Various inch indicators
  5'10inches  Various inch indidators
  5'10inchs   This bad spelling case is known
  5f10        Various foot indicators
  5ft10       Various foot indicators
  5foot10     Various foot indicators
  5feet10     Various foot indicators
  5foot10"    Indicates can be compiled any way
  5FEET10     Case insensitive
  5' 10"      Whitespace is ignored

=head2 Storage and Conversion

Regardless of the method that the value is entered, all values are stored
internally in centimetres. The default string form of all measurements is
also in centimetres.

This is a specific design decision, as there is a long term world trend
towards increased metrification. Many countries (such as Germany) use metric
values even for the "common man's" understanding of things and people do not
know their height in feet and inches.

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

=head2 new $height

The C<new> constructor takes a height string and returns a new object
representing the height measurement, or C<undef> if there is a problem with
the value provided.

Currently, there is no explanation of the reason why a value is rejected.
Any used may need to just be presented with an "Invalid Value" message.

In future, a mechanism to access error messages following an error will
be added.

=cut

sub new {
	my $class = ref $_[0] || $_[0];
	my $value = defined $_[1] ? lc $_[1] : return undef;
	$value =~ s/\s//g;

	# Basic metric
	if ( $value =~ /^(\d{2,3}(?:\.5)?)\s*(?:c|cm|cms)?$/ ) {
		my $cm = 0 + $1;
		unless ( $cm > 30 and $cm < 300 ) {
			# Impossibly out of range
			return undef;
		}
		return bless { value => $cm }, $class;
	}

	# Basic imperial
	if ( $value =~ /^(\d)(?:\'|f|ft|foot|feet)(\d{1,2}(?:\.5)?)(?:\"|i|in|inc|inch|inchs|inches)?$/ ) {
		my $feet = 0 + $1;
		my $inch = 0 + $2;
		unless ( $feet >= 1 and $feet <= 8 ) {
			# Impossibly out of range
			return undef;
		}
		unless ( $inch >= 0 and $inch < 12 ) {
			# Illegal value
			return undef;
		}

		# Convert to cm
		my $cm = Data::Vitals::Util::inch2cm($feet * 12 + $inch) or return undef;
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

# Generic string form, which is currently set to cms.
# Normally, given the American bias in programming, I would have done
# this as feet and inches. However there is a long term trend towards
# metrification, and from a support issue it is better to be a bit more
# aggressive and use standard units by default earlier, rather than be
# stuck with a default string form that nobody uses in future years.
sub as_string { shift->as_metric }

###------------------------------------------------------------------

=pod

=head2 as_metric

The C<as_metric> method returns the metric form of the measurement, which
for height measurements is always in centimetres.

=cut

sub as_metric { shift->as_cms }

###------------------------------------------------------------------

=pod

=head2 as_imperial

The C<as_imperial> method returns the imperial form of the measurement,
which for height measurements is in feet and inches

=cut

sub as_imperial { shift->as_feet }

###------------------------------------------------------------------

=pod

=head2 as_cms

The C<as_cms> method explicitly returns the measurement in centimetres.

The format of the string returned is similar to C<180cm>.

=cut

sub as_cms { $_[0]->{value} . 'cm' }

###------------------------------------------------------------------

=pod

=head2 as_feet

The C<as_feet> method explicitly returns the measurement in feet and
inches.

The format of the string returned is similar to C<5'10">

=cut

sub as_feet {
	my $inch = Data::Vitals::Util::cm2inch($_[0]->{value});
	my $feet = int($inch / 12);
	$inch = $inch % 12;
	"$feet'$inch\"";
}

###------------------------------------------------------------------

1;

=pod

=head1 TO DO

- Add support for metres "1.84m"

- Add a new class as an abstract for both height, circumference, and other
length measurements.

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
