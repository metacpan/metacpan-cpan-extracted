#!/usr/bin/perl -w

# Copyright 2008, 2016 Kevin Ryde

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
use Data::Dumper;

sub expose {
  my ($widget, $event, $userdata) = @_;
  my $clip_rect = $event->area;

  my $layout = $widget->create_pango_layout ('');
  my $context = $layout->get_context;
  print "base gravity ",$context->get_base_gravity,"\n";
  print "gravity ",$context->get_gravity,"\n";
  $context->set_base_gravity ('auto');
  $layout->set_markup ('<span gravity="east">Five</span>');

  my $attrlist = $layout->get_attributes;
  my $iterator = $attrlist->get_iterator;
  my @attrs = $iterator->get_attrs;
  foreach my $attr (@attrs) {
    $attr->end_index(-1);
    print $attr," ",$attr->value,
      " ",$attr->start_index," ",$attr->end_index,"\n";
  }

  my $matrix = Gtk2::Pango::Matrix->new;
  #   $matrix->rotate (90);
  $context->set_matrix ($matrix);

  my ($str_width, $str_height) = $layout->get_pixel_size;
  print "${str_width}x$str_height\n";

  my ($ink_rect, $log_rect) = $layout->get_extents;
  my $rect = $matrix->transform_rectangle ($log_rect);
  print Dumper($rect),"\n";
  print $rect->{'width'} / Gtk2::Pango->scale,"x",
    $rect->{'height'} / Gtk2::Pango->scale,"\n";

  my $win = $widget->window;
  my $style = $widget->get_style;
  my $state = $widget->state;
  $style->paint_layout ($win,
                        $state,
                        1, # use text gc
                        $clip_rect,
                        $widget,
                        'gravity.pl',
                        0, 0,
                        $layout);
  return 0; # propagate
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (500, 300);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $label = Gtk2::Label->new ('Foo');
$vbox->pack_start ($label, 0,0,0);

my $area = Gtk2::DrawingArea->new;
$area->signal_connect (expose_event => \&expose);
$vbox->pack_start ($area, 1,1,0);

$toplevel->show_all;
Gtk2->main;
exit 0;
















# package My::CellRendererTextRotate;
# use strict;
# use warnings;
# use Glib::Object::Subclass 'Gtk2::CellRendererText'
#   properties => [ Glib::ParamSpec->float
#                   ('rotation',
#                    'rotation',
#                    'Blurb.',
#                    Glib::G_PARAM_READWRITE),
#                 ];
# 
# sub INIT_INSTANCE {
#   my $context = $self->{'context'} = Gtk2::Pango::Context->new;
#   $self->{'layout'} = Gtk2::Pango::Layout->new ($context);
# }
# 
# sub SET_PROPERTY {
#   my ($self, $pspec, $newval) = @_;
#   if ($pspec->name eq 'rotation') {
#     my $context = $self->{'context'};
#     my $matrix = Gtk2::Pango::Matrix->new;
#     $matrix->rotate ($newval);
#     $context->set_matrix ($matrix);
#   }
# }
# 
# sub GET_SIZE {
#   my ($self, $widget, $cell_area) = @_;
#   
#   my $layout = $self->{'layout'};
#   $layout->
# 
# 
#      return (x_offset, y_offset, width, height)


# # my $attrlist = Gtk2::Pango::AttrList->new;
# # $attrlist->insert (Gtk2::Pango::AttrGravity->new ('east'));
# # $cellrenderer->set (attributes => $attrlist);
# 

