# centre of screen instead of under mouse ?


# Copyright 2007, 2008, 2009, 2010, 2011, 2015 Kevin Ryde

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

package App::Chart::Gtk2::Ex::MenuBits;
use 5.008;
use strict;
use warnings;
use Gtk2 1.200; # for Gtk2::GDK_CURRENT_TIME()

# uncomment this to run the ### lines
#use Smart::Comments;

sub position_screen_centre {
  my ($menu) = @_;
  ### position_screen_centre()

  my $menu_req = $menu->requisition;
  my $screen = $menu->get_screen;

  # returning $push_in==1 will move these if negative due to menu bigger
  # than screen
  my $x = int (($screen->get_width - $menu_req->width)/ 2);
  my $y = int (($screen->get_height - $menu_req->height) / 2);
  ###  $x
  ###  $y
  return ($x, $y, 1);
}

# usually $event->button, $event->time is enough ...
#
sub menu_popup_for_event {
  my ($menu, $event) = @_;
  my $button = (Scalar::Util::blessed($event) && event_is_button_press($event)
                ? $event->button : 0);
  my $time = (Scalar::Util::blessed($event) && $event->can('time')
              ? $event->time
              : Gtk2::GDK_CURRENT_TIME);  # 1.200 or something
  $menu->popup (undef,  # parent menushell
                undef,  # parent menuitem
                undef,  # position func
                undef,  # data
                $button,
                $time);
}

my %event_types_button_press = ('button-press'  => 1,
                                '2button-press' => 1,
                                '3button-press' => 1);

# return true if $event is a button press, either a plain press or a double
# or triple click
sub event_is_button_press {
  my ($event) = @_;
  return $event_types_button_press{$event->type};
}

1;
__END__

=for stopwords popup

=head1 NAME

App::Chart::Gtk2::Ex::MenuBits -- miscellaneous Gtk2::Menu helpers

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::MenuBits;

=head1 FUNCTIONS

=over 4

=item C<< ($x,$y,$push_in) = App::Chart::Gtk2::Ex::MenuBits::position_screen_centre ($menu, $x, $y, $userdata) >>

Position a menu in the centre of the screen.  The input C<$x>, C<$y> and
C<$userdata> are currently ignored (pass C<undef> for C<$userdata>).

=back

=head1 SEE ALSO

L<Gtk2::Ex::WidgetBits>,
L<Gtk2::Ex::MenuBits>

=cut
