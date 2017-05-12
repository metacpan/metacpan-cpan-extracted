#!/usr/bin/perl -w

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

use strict;
use warnings;
use 5.010;
use Gtk2 '-init';
use Gtk2::Ex::TextBufferBits;

my $long = <<'HERE'; #  . ("xx\n" x 50000);
1. This is a long line fjkdsa jfkd jkf djakf jdsak fjkd ajfk jkf sdjak fjdksa fjkasd fjk sdajfk sdjakf sdjka fksdja fksd akfsdafdja fkds lafjks dajfkl sdajklf a.
2.
3. And another long line fjkdsa jfkd jkf djakf jdsak fjkd ajfk jkf sdjak fjdksa fjkasd fjk sdajfk sdjakf sdjka fksdja fksd akfsdafdja fkds lafjks dajfkl sdajklf a.
s
x
x
x
d
fsf
wef
w
weg
weg
wg3w
gw
g3wg
3g3
wg
w3g3w
HERE

my $short = <<'HERE';
1. abc
2. def

4. xx
5.
6.
7.

9.
HERE
print "long is ",length($long),"\n";

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $buttonbox = Gtk2::VBox->new;
$hbox->pack_start ($buttonbox, 0,0,0);

my $scrolled = Gtk2::ScrolledWindow->new;
$scrolled->set_policy ('automatic', 'automatic');
$hbox->pack_start ($scrolled, 1,1,0);

my $textbuf = Gtk2::TextBuffer->new;
$textbuf->set_text ($long);

my $textview = Gtk2::TextView->new_with_buffer ($textbuf);
$textview->set (wrap_mode => 'char',
                editable => 1);
$scrolled->add ($textview);

my $method = \&Gtk2::Ex::TextBufferBits::replace_lines;
{
  my $button = Gtk2::RadioButton->new_with_label (undef, 'replace_lines');
  $button->signal_connect
    (toggled => sub {
       my ($button) = @_;
       if ($button->get_active) {
         $method = 'Gtk2::Ex::TextBufferBits::replace_lines';
         print "method now $method\n";
       }
     });
  $buttonbox->pack_start ($button, 0,0,0);

  $button = Gtk2::RadioButton->new_with_label ($button, 'set_text');
  $button->signal_connect
    (toggled => sub {
       my ($button) = @_;
       if ($button->get_active) {
         $method = 'set_text';
         print "method now $method\n";
       }
     });
  $buttonbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Long');
  $button->signal_connect
    (clicked => sub {
       print "$method long\n";
       $textbuf->$method ($long);
     });
  $buttonbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Short');
  $buttonbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub {
       print "$method short\n";
       $textbuf->$method ($short);
     });
}
{
  my $button = Gtk2::Button->new_with_label ('Marks');
  $buttonbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub {
       print "marks\n";
       #        print "insert    "; print_mark ($textbuf->get_insert);
       #        print "selection "; print_mark ($textbuf->get_selection_bound);
       my $iter = $textbuf->get_start_iter;
       foreach my $mark (textbuf_all_marks ($textbuf)) {
         print_mark ($mark);
       }
     });

  sub print_mark {
    my ($mark) = @_;
    my $textbuf = $mark->get_buffer;
    my $miter = $textbuf->get_iter_at_mark ($mark);
    printf "%-20s %3d %2d,%-2d %5s %s %s\n",
      $mark->get_name // 'undef',
        $miter->get_offset,
          $miter->get_line, $miter->get_line_offset,
            ($mark->get_left_gravity?"left":"right"),
              ($mark->get_visible?"visible":"not-visible"),
                ($mark->get_deleted?"deleted":"not-deleted");
  }
}

{
  my $button = Gtk2::Button->new_with_label ('First Longer');
  $buttonbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub {
       my $str = $textbuf->get_text ($textbuf->get_start_iter,
                                     $textbuf->get_end_iter,
                                     1);
       $str =~ s/\n/ zzz\n/;
       print "$method first longer\n";
       $textbuf->$method ($str);
     });
}
{
  my $button = Gtk2::Button->new_with_label ('First Empty');
  $buttonbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub {
       my $str = $textbuf->get_text ($textbuf->get_start_iter,
                                     $textbuf->get_end_iter,
                                     1);
       $str =~ s/[^\n]*//;
       print "$method first empty\n";
       $textbuf->$method ($str);
     });
}
{
  my $button = Gtk2::CheckButton->new_with_label ('editable');
  $buttonbox->pack_start ($button, 0,0,0);
  require Glib::Ex::ConnectProperties;
  Glib::Ex::ConnectProperties->new ([$textview,'editable'],
                                    [$button,'active']);
}

# not practical, 150kbytes takes 10 seconds
sub textbuf_all_marks {
  my @ret;
  my $iter = $textbuf->get_start_iter;
  for (;;) {
    push @ret, $iter->get_marks;
    if ($iter->is_end) { last; }
    $iter->forward_char;
  }
  return @ret;
}

$toplevel->show_all;
Gtk2->main;
exit 0;
