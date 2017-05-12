# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Perl DateTime extension for providing localised strings for the French Revolutionary calendar
# Copyright (c) 2003, 2004, 2010, 2011, 2014, 2016 Jean Forget. All rights reserved.
#
# See the license in the embedded documentation below.
#

package DateTime::Calendar::FrenchRevolutionary::Locale;

use utf8;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.14'; # same as parent module DT::C::FR

sub load {
  my ($self, $lang) = @_;
  my $real_class = "DateTime::Calendar::FrenchRevolutionary::Locale::$lang";
  eval "require $real_class";
  die $@ if $@;
  return $real_class->new();
}
# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
"Amour sacré de la patrie, conduis soutiens nos bras vengeurs.";

__END__

=encoding utf8

=head1 NAME

DateTime::Calendar::FrenchRevolutionary::Locale - Dates in the French Revolutionary Calendar

=head1 DESCRIPTION

Please refer to parent module:

  perldoc DateTime::Calendar::FrenchRevolutionary

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See L<http://lists.perl.org/> for more details.

Please enter bug reports at L<http://rt.cpan.org/>

=head1 AUTHOR

Jean Forget <JFORGET@cpan.org>

=head1 LICENSE STUFF

Copyright (c)  2003, 2004,  2010, 2012, 2014,  2016 Jean  Forget.  All
rights reserved.  This program is  free software. You  can distribute,
modify,  and otherwise  mangle DateTime::Calendar::FrenchRevolutionary
under the same terms as perl 5.16.3.

This program is  distributed under the same terms  as Perl 5.16.3: GNU
Public License version 1 or later and Perl Artistic License

You can find the text of the licenses in the F<LICENSE> file or at
L<http://www.perlfoundation.org/artistic_license_1_0> and
L<http://www.gnu.org/licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is  free software; you can redistribute  it and/or modify
it under the  terms of the GNU General Public  License as published by
the Free  Software Foundation; either  version 1, or (at  your option)
any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See  the GNU
General Public License for more details.

You  should have received  a copy  of the  GNU General  Public License
along with this program; if not, see <http://www.gnu.org/licenses/> or
write to the Free Software Foundation, Inc., L<http://fsf.org>.

=cut
