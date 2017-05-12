# Copyright 2010 Kevin Ryde

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


package App::Chart::Gtk2::Ex::TextViewBits;
use 5.010;
use strict;
use warnings;

# uncomment this to run the ### lines
#use Smart::Comments;

sub window_linenum {
  my ($textview) = @_;
  my ($x, $y) = $textview->window_to_buffer_coords ('text', 0, 0);
  my ($win_iter, $line_top) = $textview->get_line_at_y ($y);
  return $win_iter->get_line;
}


# TextBufferBits replace_lines() better

# sub replace_text {
#   my ($textview, $str) = @_;
#   ### TextViewBits replace_text()
#   my $linenum = window_linenum ($textview);
#   ### window linenum: $linenum
# 
#   my $textbuf = $textview->get_buffer;
#   $textbuf->set_text ($str);
# 
#   # Had lots of trouble here.  scroll_to_iter didn't take effect unless
#   # called twice, and then stubbornly refused to put the last page visible.
#   # scroll_to_mark works, but the first time through have to do a
#   # place_cursor or else it starts off showing the end of the buffer instead
#   # of the start. :-(
#   #
#   # Still not quite right if you do it too rapidly :-(
#   #
#   my $iter = $textbuf->get_iter_at_line ($linenum);
#   $textbuf->place_cursor ($iter);
#   my $mark = $textbuf->get_mark (__PACKAGE__);
#   if ($mark) { $textbuf->move_mark ($mark, $iter); }
#   else { $mark = $textbuf->create_mark (__PACKAGE__, $iter, 0); }
#   $textview->scroll_to_mark ($mark, 0, 1, 0.0, 0.0);
# }

# =item C<< App::Chart::Gtk2::Ex::TextViewBits::replace_text ($textview, $str) >>
# 
# Replace the text in C<$textview>'s buffer, preserving its window position.


1;
__END__

=for stopwords Ryde Chart

=head1 NAME

App::Chart::Gtk2::Ex::TextViewBits -- helpers for Gtk2::TextView widgets

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::TextViewBits;

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::TextViewBits::window_linenum ($textview) >>

Return the line number of the first visible or partly-visible line in
C<$textview>, numbered starting from 0 for the first line (the same as a
C<Gtk2::TextIter> uses).

=back

=head1 SEE ALSO

L<Gtk2::TextView>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENSE

Copyright 2010 Kevin Ryde

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
