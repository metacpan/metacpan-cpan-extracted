package Data::Vitals::Underarm;

=pod

=head1 NAME

Data::Vitals::Underarm - A measurement of the circumference of the torso
underneath the arms

=head1 INHERITANCE

  Data::Vitals::Circumference
  `--> Data::Vitals::Underarm

=head1 DESCRIPTION

Data::Vitals::Underarm is part of the
L<Perl "Vital Statistics" Library|Data::Vitals>.

It is a very simple class that allows you to create objects that represent a
single measurement of the circumference of the human torso taken underneath
the arms.

In women, this is used along with L<Data::Vitals::Chest> in one of the two
methods used to determine bra size, particularly nursing bras.

=head2 Taking this Measurement

The underarm measurement is generally taken with a tape measure around the
torso at a position just underneath the arms, while standing straight and
breathing normally. It should be as high as possible while still comfortable.
Do not agressively force the tape into the arm pits.

More information and diagrams are available at
L<http://www.pumpstation.com/frmBraSize-1.cfm>.

=head1 METHODS

Data::Vitals::Underarm is implemented primarily in
L<Data::Vitals::Circumference> and shares all its methods.

Data::Vitals::Underarm does not have any additional methods unique to it.

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
