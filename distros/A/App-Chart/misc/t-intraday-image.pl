#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Gtk2 '-init';
use App::Chart::Gtk2::IntradayImage;

use FindBin;
my $progname = $FindBin::Script;

if (0) {
  require I18N::Langinfo::Wide;
  my $loader = Gtk2::Gdk::PixbufLoader->new();
  my $pixbuf;
  if (eval {
    $loader->write ("djkfsljdksl");
    $loader->close ();
    $pixbuf = $loader->get_pixbuf ();
    1 }) {
    print "pixbuf loader ok\n";
  } else {
    my $err = $@;
    print "pixbuf loader error\n";
    require Data::Dumper;
    print Data::Dumper::Dumper(\$err);
    print "message ", $err->message, "\n";
    print "location ", I18N::Langinfo::Wide::to_wide($err->location), "\n";
  }
  exit 0;
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

#my $layout = $image;
# my $layout = Gtk2::Layout->new;
# my $layout = Gtk2::VBox->new;
my $layout = Gtk2::EventBox->new;
$hbox->pack_end ($layout, 1,1, 0);

my $image = App::Chart::Gtk2::IntradayImage->new
  (symbol => 'CLZ10.CMX', # '^GSPC',
   mode => '1d');
$image->modify_bg ('normal', Gtk2::Gdk::Color->new(0,0,0,0));
print "flags ",$image->flags,"\n";
$layout->add ($image);

my $accelgroup = Gtk2::AccelGroup->new;
$toplevel->add_accel_group ($accelgroup);
$accelgroup->connect (Gtk2::Gdk->keyval_from_name('l'), ['control-mask'], [],
                      \&redraw_half);

my $vbox = Gtk2::VBox->new;
$hbox->pack_start ($vbox, 0, 0, 0);

{
  my $button = Gtk2::Button->new_with_label ('1d');
  $button->signal_connect (clicked => sub { $image->set(mode => '1d'); });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('5d');
  $button->signal_connect (clicked => sub { $image->set(mode => '5d'); });
  $vbox->pack_start ($button, 0, 0, 0);
}
sub redraw_half {
  my $win = $image->window;
  my ($width, $height) = $win->get_size;
  $image->queue_draw_area(0, 0,
                          $width, $height/2);
}
{
  my $button = Gtk2::Button->new_with_label ('Redraw half');
  $button->signal_connect (clicked => \&redraw_half);
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  require Gtk2::Ex::CrossHair;
  require Glib::Ex::ConnectProperties;
  my $crosshair = Gtk2::Ex::CrossHair->new (widget => $image,
                                            foreground => 'orange');
  #   $crosshair->signal_connect (moved => sub {
  #                                 print "$progname: crosshair moved\n";
  #                               });
  my $button = Gtk2::CheckButton->new_with_label ('Crosshair');
  Glib::Ex::ConnectProperties->new ([$button,'active'],
                                    [$crosshair,'active']);
  $button->signal_connect
    ('notify::active' => sub {
       print "$progname: cross @{[$crosshair->get('active')]}\n";
     });
  $vbox->pack_start ($button, 0,0,0);
}

$toplevel->show_all;
Gtk2->main;

exit 0;
