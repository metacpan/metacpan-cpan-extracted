package Data::Vitals::Hips;

=pod

=head1 NAME

Data::Vitals::Hips - A measurement of the circumference of the hips

=head1 INHERITANCE

  Data::Vitals::Circumference
  `--> Data::Vitals::Hips

=head1 DESCRIPTION

Data::Vitals::Hips is part of the
L<Perl "Vital Statistics" Library|Data::Vitals>.

It is a very simple class that allows you to create objects that represent a
single measurement of the circumference of the hips.

Please note that this measurement does B<not> refer to the "high hips"
measurement. This is a different value, for which a class does not yet exist.

=head2 Taking this Measurement

Place the measuring tape around the body at the fullest part of the seat.
Pull the measuring tape so it conforms to the body and does not fall down,
but do not pull it tight.

More information and diagrams are available at
L<http://www.sewing.org/enthusiast/html/el_bodymeasure.html>.

=head1 METHODS

Data::Vitals::Hips is implemented primarily in
L<Data::Vitals::Circumference> and shares all its methods.

Data::Vitals::Hips does not have any additional methods unique to it.

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
