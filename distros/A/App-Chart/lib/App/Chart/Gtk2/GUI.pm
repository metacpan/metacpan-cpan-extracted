# GUI shared functions.

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::GUI;
use 5.006;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');
use Glib;
use Gtk2;
use Gtk2::Pango;

use App::Chart;

# uncomment this to run the ### lines
#use Smart::Comments;

Glib::set_application_name (__('Chart'));
Gtk2::Window->set_default_icon_from_file
  (App::Chart::datafilename ('chart.xpm'));
Gtk2->CHECK_VERSION(2,12,0)
  or die "App::Chart needs Gtk 2.12 or higher";


#------------------------------------------------------------------------------

# Perl-Gtk 1.221 no undef
sub menu_set_screen {
  my ($menu, $screen) = @_;
  #   $screen ||= do {
  #     my $display;
  #     ($display = Gtk2::Gdk::Display->get_default)
  #       && $display->get_default_screen;
  #   };
  if ($screen) {
    $menu->set_screen ($screen);
  }
}

#------------------------------------------------------------------------------

sub string_width {
  my ($widget_or_layout, $str) = @_;
  ### string_width(): "$widget_or_layout"
  ### $str
  my $layout;
  if ($widget_or_layout->can ('create_pango_layout')) {
    # if widget instead of layout
    $layout = $widget_or_layout->create_pango_layout ($str);
  } else {
    $layout = $widget_or_layout;
    $layout->set_text ($str);
  }
  my ($width, $height) = $layout->get_pixel_size;
  return $width;
}


#------------------------------------------------------------------------------

# FIXME: really want to clip to the region, not an enclosing rect.  The
# style paint might be some nice drawing, but the default is a pretty simple
# gdk_draw_layout().
#
sub draw_text_centred {
  my ($widget, $region_or_event, $str) = @_;
  my $win = $widget->window || return; # unrealized

  my $clip_rect = $region_or_event && do {
    if (my $func = $region_or_event->can('get_clipbox')) {
      $func->($region_or_event);
    } else {
      $region_or_event->area;
    }
  };

  my $alloc = $widget->allocation;
  my $layout = $widget->create_pango_layout ($str);
  $layout->set_wrap ('word-char');
  $layout->set_width ($alloc->width * Gtk2::Pango::PANGO_SCALE);
  my ($str_width, $str_height) = $layout->get_pixel_size;
  my $x = max (0, ($alloc->width  - $str_width)  / 2);
  my $y = max (0, ($alloc->height - $str_height) / 2);
  if ($widget->get_flags & 'no-window') {
    $x += $alloc->x;
    $y += $alloc->y;
  }
  my $style = $widget->get_style;
  $style->paint_layout ($win,
                        $widget->state,
                        1, # use text gc
                        $clip_rect,
                        $widget,
                        'centred-text',
                        $x, $y, $layout);
}


#------------------------------------------------------------------------------

sub chart_style_class {
  my ($class) = @_;
  _chart_style_parse();
  $class =~ s/:/_/g;
  Gtk2::Rc->parse_string
      ("class \"$class\" style:gtk \"Chart_style\"");
}
sub chart_style_widget {
  my ($name) = @_;
  _chart_style_parse();
  Gtk2::Rc->parse_string
      ("widget \"*.$name\" style:application \"Chart_style\"");
}
use constant::defer _chart_style_parse => sub {
  Gtk2::Rc->parse_string (<<'HERE');
style "Chart_style" {
  # white on black
  fg[ACTIVE]        = { 1.0, 1.0, 1.0 }
  fg[NORMAL]        = { 1.0, 1.0, 1.0 }
  fg[PRELIGHT]      = { 1.0, 1.0, 1.0 }
  fg[SELECTED]      = { 1.0, 1.0, 1.0 }
  fg[INSENSITIVE]   = { 1.0, 1.0, 1.0 }
  text[ACTIVE]      = { 1.0, 1.0, 1.0 }
  text[NORMAL]      = { 1.0, 1.0, 1.0 }
  text[PRELIGHT]    = { 1.0, 1.0, 1.0 }
  text[SELECTED]    = { 1.0, 1.0, 1.0 }
  text[INSENSITIVE] = { 1.0, 1.0, 1.0 }

  bg[ACTIVE]        = { 0, 0, 0 }
  bg[NORMAL]        = { 0, 0, 0 }
  bg[PRELIGHT]      = { 0, 0, 0 }
  bg[SELECTED]      = { 0, 0, 0 }
  bg[INSENSITIVE]   = { 0, 0, 0 }
  base[ACTIVE]      = { 0, 0, 0 }
  base[NORMAL]      = { 0, 0, 0 }
  base[PRELIGHT]    = { 0, 0, 0 }
  base[SELECTED]    = { 0, 0, 0 }
  base[INSENSITIVE] = { 0, 0, 0 }
}
HERE
  return; # nothing
};


#------------------------------------------------------------------------------

# $uri is either a string or a URI object
sub browser_open {
  my ($uri, $parent_widget) = @_;
  $uri = "$uri";  # stringize URI object
  ### browser_open(): $uri

  if (Gtk2->can('show_uri')) { # new in Gtk 2.14
    my $screen = $parent_widget && $parent_widget->get_screen;
    if (eval { Gtk2::show_uri ($screen, $uri); 1 }) {
      return;
    }
    # possible Glib::Error "operation not supported" on http urls
    ### show_uri() error: $@
  }

  # The quoting, or lack thereof, expected of the url in openURL is in
  # mozilla XRemoteService.cpp.  It looks for ( ) delims, then the last ","
  # is the last arg to take off new-window, new-tab, noraise, etc.
  {
    my @command = ('mozilla', '-remote', "openURL($uri,new-window)");
    ### run: @command
    if (system (@command) == 0) {
      return;
    }
    ### run status: $?
    ### error: "$!"
  }
  {
    my @command = ('sensible-browser', $uri);
    if (_spawn (@command)) { return }
  }
  {
    my @command = ('mozilla', $uri);
    if (_spawn (@command)) { return }
  }
  warn "Cannot run browser: none of show_uri, sensible-browser or mozilla work";
}
sub _spawn {
  my @command = @_;
  ### spawn(): @command
  require Proc::SyncExec;
  my $pid = Proc::SyncExec::sync_exec (\&_spawn_detach, @command);
  if (! defined $pid) {
    ### cannot run: $!
    return 0;
  }
  if (waitpid ($pid, 0) != $pid) {
    warn "Error waiting spawned $pid: $!\n";
  }
  return 1;
}
sub _spawn_detach {
  if (my $pid = Proc::SyncExec::fork_retry()) {
    POSIX::_exit (0); # parent
  } else {
    ## no critic (RequireCheckingReturnValueOfEval)
    eval { POSIX::setsid() };
    return 1; # ok, child continues
  }
}

#-----------------------------------------------------------------------------

sub color_object {
  my ($widget, $colour_str) = @_;
  if (defined $colour_str) {
    require App::Chart::Gtk2::Ex::GdkColorAlloc;
    return ($colour_str,
            $widget->{'color'}->{$colour_str}
            ||= App::Chart::Gtk2::Ex::GdkColorAlloc->new (widget => $widget,
                                              color  => $colour_str));
  } else {
    return ('fg', $widget->style->fg($widget->state));
  }
}

sub gc_for_colour {
  my ($widget, $colour_str) = @_;
  ($colour_str, my $color_obj) = color_object ($widget, $colour_str);
  return ($widget->{'gc_solid'}->{$colour_str} ||= do {
    require App::Chart::Gtk2::Ex::GtkGCBits;
    App::Chart::Gtk2::Ex::GtkGCBits->get_for_widget
        ($widget, { foreground => $color_obj,
                    line_style => 'solid',
                    line_width => 0 })
      });
}
sub gc_for_colour_dashed {
  my ($widget, $colour_str) = @_;
  ($colour_str, my $color_obj) = color_object ($widget, $colour_str);
  return ($widget->{'gc_dash'}->{$colour_str} ||= do {
    require App::Chart::Gtk2::Ex::GtkGCBits;
    App::Chart::Gtk2::Ex::GtkGCBits->get_for_widget
        ($widget, { foreground => $color_obj,
                    line_style => 'on_off_dash',
                    line_width => 0 })
      });
}

1;
__END__

# =for stopwords Pango undef Gtk ListStore TreeStore renderer TreeViewColumn TreeView
#
# =head1 NAME
# 
# App::Chart::Gtk2::GUI -- miscellaneous graphical interface functions
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Gtk2::GUI;
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =cut
# 
# =item App::Chart::Gtk2::GUI::string_width ($widget_or_layout, $str)
# 
# Return the width in pixels of C<$str> in the font of the given widget or
# layout (either a C<Gtk2::Widget> or a C<Gtk2::Pango::Layout> object).
# 
# =cut
# 
# =item C<< App::Chart::Gtk2::GUI::draw_text_centred ($widget, $region_or_event, $string) >>
# 
# Draw C<string> centred in the window of C<widget>.  If C<widget> isn't
# realized yet then do nothing.  Pango C<word-char> wrapping is enabled, so
# the string is not truncated if it's wider than the window.
# 
# Both windowed and no-window widgets can be given here.  C<$region_or_event>
# gives a region to clip to, or undef to draw everything.
# 
# =cut
# 
# =item App::Chart::Gtk2::GUI::chart_style_class ($class)
# 
# =item App::Chart::Gtk2::GUI::chart_style_widget ($widgetname)
# 
# Setup package C<$class> or widget C<$widgetname> (per
# C<< $widget->set_name >>) to get the Chart graph style settings, which means
# black background and white foreground and text.
# 
# C<$class> can include colons like C<"App::Chart::Gtk2::HAxis"> and they're turned
# into underscores like C<"App__Chart__Gtk2__HAxis"> which is the Gtk class
# name.
# 
# =cut
# 
# =back
