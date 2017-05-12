# instance per-screen ?
# instance per-display and move to screen ?
#
# searching through list_toplevels picks up non-instance created windows
# too, maybe flag those created this way ...
#
# isa() in search might rightly or wrongly pick up subclasses


# Copyright 2009, 2010 Kevin Ryde

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

package App::Chart::Gtk2::Ex::ToplevelSingleton;
use 5.008;
use strict;
use warnings;
use List::Util;
use App::Chart::Gtk2::Ex::ToplevelBits;

# uncomment this to run the ### lines
#use Smart::Comments;

sub import {
  my ($class, %options) = @_;
  if (%options) {
    no strict 'refs';
    ${"${class}::_instance_options"} = \%options;
  }
}

# ClassName->has_instance ()
sub has_instance {
  my $class = shift;
  return $class->has_instance_for_screen (undef, @_);
}
# ClassName->has_instance_for_screen ($screen)
sub has_instance_for_screen {
  my ($class, $screen) = @_;
  $screen = App::Chart::Gtk2::Ex::ToplevelBits::_screen($screen);

  # searching like this isn't fast, but it allows a toplevel to be moved to
  # a different screen
  return List::Util::first { ($_->isa($class) && $_->get_screen == $screen) }
    Gtk2::Window->list_toplevels;
}

# ClassName->instance (args...)
sub instance {
  my $class = shift;
  return $class->instance_for_screen (undef, @_);
}

# ClassName->instance_for_screen ($screen, args...)
sub instance_for_screen {
  my ($class, $screen) = (shift, shift);

  return $class->has_instance_for_screen($screen)
    || do {
      ### ToplevelSingleton instance create
      $class->new_instance (screen => App::Chart::Gtk2::Ex::ToplevelBits::_screen($screen),
                            @_);
    };
}

# default instance constructor
sub new_instance {
  my ($class) = @_;
  my $self = Glib::Object::new (@_);
  my $options = do { no strict 'refs';
                     ${"${class}::_instance_options"} };
  if ($options->{'hide_on_delete'}) {
    $self->signal_connect (delete_event => \&Gtk2::Widget::hide_on_delete);
  }
  return $self;
}

1;
__END__


# # ClassName->has_instance_for_display ($display)
# sub has_instance_for_display {
#   my ($class, $display) = @_;
#   $display = _display($display);
# 
#   # searching like this isn't fast, but it allows a toplevel to be moved to
#   # a different display
#   return List::Util::first { ($_->isa($class) && $_->get_display == $display) }
#     Gtk2::Window->list_toplevels;
# }
# # ClassName->instance_for_display ($display, args...)
# sub instance_for_display {
#   my ($class, $display) = (shift, shift);
# 
#   return ($class->has_instance_for_display($display)
#           || $class->instance_for_screen($display, @_));
# }
# sub _display {
#   my ($obj) = @_;
#   if (! defined $obj) {
#     return Gtk2::Gdk::Screen->get_default->get_display;
#   }
#   if ($obj->can('get_display')) {
#     $obj = $obj->get_display
#       || croak "No display for target $obj";
#   }
#   return $obj;
# }

#  return ($display->{(__PACKAGE__)}->{$class} ||= do {

#  $instance->signal_connect (destroy => \&_do_destroy, $class);
# sub _do_destroy {
#   my ($instance, $class) = @_;
#   my $display = $instance->get_display;
#   if (($display->{(__PACKAGE__)}->{$class}||0) == $instance) {
#     delete $display->{(__PACKAGE__)}->{$class};
#   }
# }

# use Class::Singleton 1.04;  # 1.04 for has_instance()
# use base 'Class::Singleton';
# 
# sub instance {
#   my $class = shift;
#   return $class->has_instance
#     || do {
#       my $instance = $class->SUPER::instance;
#       $instance->signal_connect (destroy => \&_do_destroy, $ivar);
#       $instance
#     };
# }
# 
# sub _do_destroy {
#   my ($instance, $ivar) = @_;
#   if (($instance->has_instance || 0) == $instance) {
#     undef $ivar;
#   }
# }

=for stopwords toplevel multi

=head1 NAME

App::Chart::Gtk2::Ex::ToplevelSingleton -- single instance of toplevel window

=for test_synopsis my ($toplevel)

=head1 SYNOPSIS

 package MyToplevel;
 use Gtk2;
 use Glib::Object::Subclass 'Gtk2::Window';
 use base 'App::Chart::Gtk2::Ex::ToplevelSingleton';

 use App::Chart::Gtk2::Ex::ToplevelSingleton hide_on_delete => 1;

 $toplevel = MyToplevel->instance;
 
 if (MyToplevel->has_instance) { do_something() }

=head1 DESCRIPTION

This package is designed as a multi-inheritance mix-in for subclasses of
C<Gtk2::Window> which normally want only a single window instance, to be
used throughout a program.

After adding C<ToplevelSingleton> to your C<@ISA>,
C<< MyToplevel->instance >> returns a single shared instance of a
C<MyToplevel> window.

=head1 SEE ALSO

L<Class::Singleton>

=cut
