package Data::Vitals::Waist;

=pod

=head1 NAME

Data::Vitals::Waist - A measurement of the circumference of the torso at the
waist

=head1 INHERITANCE

  Data::Vitals::Circumference
  `--> Data::Vitals::Waist

=head1 DESCRIPTION

Data::Vitals::Waist is part of the
L<Perl "Vital Statistics" Library|Data::Vitals>.

It is a very simple class that allows you to create objects that represent a
single measurement of the circumference of the human torso at the waist.

=head2 Taking this Measurement

The waist measurement is generally taken with a tape measure around the waist,
with the tape loose, but just tight enough to avoid the tape falling.

The measurement should be taken at the inflection point. If the
waist is thinner than the hips or chest it should be taken at the thinnest
point. If the waist is larger than the hips or chest it should be taken at
the widest point.

More information and diagrams are available at
L<http://www.sewing.org/enthusiast/html/el_bodymeasure.html>.

=head1 METHODS

Data::Vitals::Waist is implemented primarily in
L<Data::Vitals::Circumference> and shares all its methods.

Data::Vitals::Waist does not have any additional methods unique to it.

=cut

use strict;
use base 'Data::Vitals::Circumference';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.05';
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
