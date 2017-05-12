# Copyright 2010, 2011 Kevin Ryde

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


package App::Chart::Gtk2::Ex::ContainerBits;
use 5.010;
use strict;
use warnings;

sub children_propagate_direction {
  my ($container) = @_;  # if signal ($self, $previous_direction, $userdata)
  my $dir = $container->get_direction;
  foreach my $child ($container->get_children) {
    $child->propagate_direction ($dir);
  }
}

1;
__END__

=for stopwords Ryde Chart

=head1 NAME

App::Chart::Gtk2::Ex::ContainerBits -- helpers for Gtk2::Container widgets

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::ContainerBits;

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::ContainerBits::children_propagate_direction ($container) >>

Propagate the C<ltr>/C<rtl> "direction" setting on C<$container> to its
child widgets.

This function can be set as a C<direction-changed> signal handler on the
container if you want to propagate future changes too.

    # propagate current setting
    App::Chart::Gtk2::Ex::ContainerBits::children_propagate_direction($container);

    # propagate any future changes
    $container->signal_handler
      (direction_changed =>
       \&App::Chart::Gtk2::Ex::ContainerBits::children_propagate_direction);

=back

=head1 SEE ALSO

L<Gtk2::Container>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENSE

Copyright 2010, 2011 Kevin Ryde

Chart is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Chart is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Chart.  If not, see L<http://www.gnu.org/licenses/>.

=cut
