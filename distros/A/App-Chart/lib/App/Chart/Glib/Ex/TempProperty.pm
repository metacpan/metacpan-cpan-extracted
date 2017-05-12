# Copyright 2008, 2009, 2010, 2011, 2012, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Glib::Ex::TempProperty;
use 5.008;
use strict;
use warnings;
use Glib;
use Carp;

sub new {
  my $class = shift;
  my $obj = shift;
  if (@_ & 1) {
    croak 'TempProperty should have an even number of propname+value arguments';
  }
  my @self = ($obj);
  my $self = bless \@self, $class;
  while (@_) {
    my $pname = shift;
    my $value = shift;
    push @self, $pname, $obj->get_property($pname);
    $obj->set_property($pname,$value);
  }
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  my $obj = shift @$self;
  while (@$self) {
    $obj->set_property(shift @$self, shift @$self);
  }
}

1;
__END__

=head1 NAME

=for stopwords TempProperty

App::Chart::Glib::Ex::TempProperty -- temporary object property setting

=for test_synopsis my ($obj, $newval)

=head1 SYNOPSIS

 use App::Chart::Glib::Ex::TempProperty;
 my $setting = App::Chart::Glib::Ex::TempProperty->new ($obj, 'propname', $newval);

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Glib::Ex::TempProperty->new ($obj, $propname) >>

=item C<< App::Chart::Glib::Ex::TempProperty->new ($obj, $propname, $newvalue) >>

Create and return a TempProperty object ...

=back

=head1 SEE ALSO

L<Glib::Ex::TieProperties>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2012, 2016 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
