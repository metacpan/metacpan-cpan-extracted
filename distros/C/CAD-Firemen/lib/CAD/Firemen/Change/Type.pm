#!/usr/bin/perl
######################
#
#    Copyright (C) 2011  TU Clausthal, Institut fuer Maschinenwesen, Joachim Langenbach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################

use strict;
use warnings;

# Pod::Weaver infos
# ABSTRACT: Constants to represant the change type of CAD::Firemen::Change

package CAD::Firemen::Change::Type;
{
  $CAD::Firemen::Change::Type::VERSION = '0.7.2';
}
use Exporter 'import';

use constant {
  NoChange => 'NoChange',
  NoSpecial => 'NoSpecial',
  Case => 'Case',
  Path => 'Path',
  ValuesChanged => 'ValuesChanged',
  DefaultValueChanged => 'DefaultValueChanged'
};

1;

__END__

=pod

=head1 NAME

CAD::Firemen::Change::Type - Constants to represant the change type of CAD::Firemen::Change

=head1 VERSION

version 0.7.2

=head1 DESCRIPTION

NoChange  - There is no change between two values.
NoSpecial - It's a normal change and not a change of the ones listed below.

Special changes:

Case                    - The values are the same, but changed in case (e.g: yes to YES)
Path                    - The values may be different, but they are paths and therefore they may change from release to release
ValuesChanged           - At least one possible value has changed (Removed or added)
DefaultValueChanged     - The default value is changed

Note that the values are strings, therefore they must be compared with "ne" and "eq" like

if($change->changeType() eq CAD::Firemen::Change::Type->NoChange){}

=head1 AUTHOR

Joachim Langenbach <langenbach@imw.tu-clausthal.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by TU Clausthal, Institut fuer Maschinenwesen.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
