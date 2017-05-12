package Data::Vitals;

=pod

=head1 NAME

Data::Vitals - The Perl "Vital Statistics" Library

=head1 DESCRIPTION

The world of clothing and fashion works to an annoyingly anacronistic and
complicated set of measurements. The Perl "Vital Statistics" Library is an
attempt to create a comprehensive set of classes, object and algorithms for
working with human-describing data such as height, body measurements, shoe,
bra and other clothing sizes.

It is not intended to be the end to a means, or the solution to a specific
problem, but rather a general package that can be used to build more specific
packages. It is intended that the library should be extremely flexible,
highly extendible, support locales in some form, and be heavily unit tested
to ensure that packages built on top of Data::Vitals have a reliable base.

Data::Vitals measurement objects are useful for both male and female
measurements.

=head2 Implementation Style

As is generally the case with complex and twisty subjects (such as
L<DateTime>) this library is implemented in a highly object-orientated
form.

For the sake of completeness we take this to rather extreme levels. For
example, a Data::Vitals::Waist object specifically refers for a
measurement of the circumference of the torso taken at a waist.

=head2 Metric and Imperial

Please note that all measurements are stored and stringified into metric
values (although they can be input in various forms). This is for forward
compability with the long term worldwide trend towards metrification. For
now, locales that use imperial values should explicitly call the various
C<< ->as_imperial >> methods.

=head2 Class List

L<Data::Vitals::Height> - Height measurement

L<Data::Vitals::Circumference> - General circumference measurement

L<Data::Vitals::Hips> - Measurement of the circumference around the hips

L<Data::Vitals::Waist> - Measurement of the circumference around the waist

L<Data::Vitals::Frame> - The "Frame" measurement. Circumference around the
chest, just below the breasts.

L<Data::Vitals::Chest> - Measurement of the circumference around the chest

L<Data::Vitals::Underarm> - Measurement of the circumference around the
torso at a position under the arms.

=head1 STATUS

This contains an implementation of Height measurements, plus a number of
measurements of the circumference of the torso at various points. i.e.
Hips/Waist/Chest/etc

Unit testing and documentation is up to date.

Please note that nothing that produces an error (by returning C<undef>) sets
an error message in any form. This will be resolved in a later version.

Please note that the measurement ranges are very large by default. The
maximum allowable values exceed by a small percentage the world records for
the various measurements (at the time of writing).

However, the minimums of the range may be unsuitable for newborn or premature
babies. The ability to customise these ranges will be added in a later
version.

=head1 METHODS

=cut

use 5.005;
use strict;

# Load the entire distribution
use Data::Vitals::Util          ();
use Data::Vitals::Height        ();
use Data::Vitals::Circumference ();
use Data::Vitals::Hips          ();
use Data::Vitals::Waist         ();
use Data::Vitals::Frame         ();
use Data::Vitals::Chest         ();
use Data::Vitals::Underarm      ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.06';
}





#####################################################################
# Constructor Shortcuts

=pod

=head2 height $height

The C<height> method creates and returns a height object. It takes as
argument a "height string".

Returns a new L<Data::Vitals::Height> object on success, or C<undef> on
error.

=cut

sub height {
	Data::Vitals::Height->new($_[1]);
}

###------------------------------------------------------------------

=pod

=head2 hips $circumference

The C<hips> method creates and returns a hip measurement object.

It takes as argument a "circumference string"
(see L<Data::Vitals::Circumference> for details)

Returns a new L<Data::Vitals::Hips> object, or C<undef> on error.

=cut

sub hips {
	Data::Vitals::Hips->new($_[1]);
}

###------------------------------------------------------------------

=pod

=head2 waist $circumference

The C<waist> method creates and returns a waist measurement object.

It takes as argument a "circumference string"
(see L<Data::Vitals::Circumference> for details)

Returns a new L<Data::Vitals::Waist> object, or C<undef> on error.

=cut

sub waist {
	Data::Vitals::Waist->new($_[1]);
}	

###------------------------------------------------------------------

=pod

=head2 frame $circumference

The C<frame> method creates and returns a "frame" measurement object.
Mainly used for women, the frame is the circumference of the torso over the
rib cage, immediately below the breasts and specifically not included any
breast material.

It takes as argument a "circumference string"
(see L<Data::Vitals::Circumference> for details)

Returns a new L<Data::Vitals::Frame> object, or C<undef> on error.

=cut

sub frame {
	Data::Vitals::Frame->new($_[1]);
}

###------------------------------------------------------------------

=pod

=head2 chest $circumference

The C<chest> method creates and returns a chest measurement object. For
women, this is also known as a "bust" measurement.

It takes as argument a "circumference string"
(see L<Data::Vitals::Circumference> for details)

Returns a new L<Data::Vitals::Chest> object on success, or C<undef> on
error.

=cut

sub chest {
	Data::Vitals::Chest->new($_[1]);
}

###------------------------------------------------------------------

=pod

=head2 bust $circumference

The C<bust> method is an alias for the L<chest|Data::Vitals/chest> method.

=cut

sub bust {
	Data::Vitals::Chest->new($_[1]);
}

###------------------------------------------------------------------

=pod

=head2 underarm $circumference

The C<underarm> method creates and returns an underarm measurement object,
which is the circumference of the torso under the arms and above (for
women) the breasts.

It takes as argument a "circumference string"
(see L<Data::Vitals::Circumference> for details)

Returns a new L<Data::Vitals::Underarm> object, or C<undef> on error.

=cut

sub underarm {
	Data::Vitals::Underarm->new($_[1]);
}

###------------------------------------------------------------------

1;

=pod

=head1 TO DO

- Allow for per-measurement ranges, that can be tweaked if needed in
special cases.

- Add Data::Vitals::Weight

- Add Data::Vitals::Bra

- Add Data::Vitals::Dress (in the various country standards)

- Add Data::Vitals::Shoe (in the various country standards)

=head1 SUPPORT

Bugs should always be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Vitals>

For other issues, contact the maintainer.

As the author is no longer working in the fashion/modelling industry,
volunteers for taking over maintenance would be gratefully accepted.

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
