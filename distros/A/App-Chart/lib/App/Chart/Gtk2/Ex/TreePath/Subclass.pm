# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::Ex::TreePath::Subclass;
use 5.008;
use strict;
use warnings;
use Gtk2;

# not "use base 'Gtk2::TreePath'" here because base.pm complains that
# Gtk2::TreePath is empty -- until it's autoloaded or something, presumably
our @ISA = ('Gtk2::TreePath');

sub new {
  my $class = shift;
  my $self = $class->SUPER::new (@_);
  return bless $self, $class; # rebless
}
sub new_first {
  my $class = shift;
  my $self = $class->SUPER::new_first (@_);
  return bless $self, $class; # rebless
}
sub new_from_indices {
  my $class = shift;
  my $self = $class->SUPER::new_from_indices (@_);
  return bless $self, $class; # rebless
}
sub new_from_string {
  my $class = shift;
  my $self = $class->SUPER::new_from_string (@_);
  # can return undef if string is bad
  return $self && bless $self, $class; # rebless
}


1;
__END__

=for stopwords TreePath reblessing subclassing subclasses Gtk2-Perl Ryde multi-inheritance Gtk

=head1 NAME

App::Chart::Gtk2::Ex::TreePath::Subclass -- TreePath constructors with reblessing

=head1 SYNOPSIS

 package My::TreePath::Variant;
 use App::Chart::Gtk2::Ex::TreePath::Subclass;
 our @ISA = ('App::Chart::Gtk2::Ex::TreePath::Subclass', 'Gtk2::TreePath');
 # ...

 package main;
 my $path = My::TreePath::Variant->new;

=head1 DESCRIPTION

C<App::Chart::Gtk2::Ex::TreePath::Subclass> helps making Perl subclasses of
C<Gtk2::TreePath>.  It provides versions of the following C<Gtk2::TreePath>
constructors

    new()
    new_first()
    new_from_indices()
    new_from_string()

They're designed as a multi-inheritance mix-in to override the corresponding
base methods in C<Gtk2::TreePath>.  They re-bless the created object into
the class name given in the call, which is what you want when subclassing,
and which the C<Gtk2::TreePath> functions don't do (as of Gtk2-Perl version
1.223).

Note that such re-blessing is only a Perl level subclass and so won't be
seen if the path object is returned back from some Gtk function, they'll
give back only plain C<Gtk2::TreePath>.

=head1 SEE ALSO

L<Gtk2::TreePath>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
