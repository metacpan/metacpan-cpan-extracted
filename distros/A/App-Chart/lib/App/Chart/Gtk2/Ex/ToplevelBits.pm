# parent => $widget ?

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Gtk2::Ex::ToplevelBits;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util;
use App::Chart::Gtk2::Ex::ToplevelSingleton;

# uncomment this to run the ### lines
#use Smart::Comments;

# screen
# parent
# with_properties
# init_properties
# modal
# hide_on_delete

sub popup {
  my ($class, %options) = @_;
  ### ToplevelBits popup(): $class

  my $properties = $options{'properties'} || {};
  my $screen = _screen
    ($options{'transient_for'} || $options{'parent'} || $options{'screen'});

  my $dialog = List::Util::first
    {$_->isa($class)
       && (! defined $screen || $_->get_screen == $screen)
         && _object_properties_equal($_,$properties)}
      Gtk2::Window->list_toplevels;
  ### ToplevelBits found: $dialog

  if ($dialog) {
    if (exists $options{'modal'}) {
      $dialog->set_modal ($options{'modal'});
    }
    if (exists $options{'transient_for'}) {
      $dialog->set_transient_for ($options{'transient_for'});
    }

  } else {
    ### new dialog $class
    if (eval { require Gtk2::Ex::WidgetCursor }) {
      Gtk2::Ex::WidgetCursor->busy;
    }

    require Module::Load;
    Module::Load::load ($class);
    $dialog = $class->Glib::Object::new
      ((defined $screen ? (screen => $screen) : ()),
       (exists $options{'modal'} ? (modal => $options{'modal'}) : ()),
       (exists $options{'transient_for'} ? (transient_for => $options{'transient_for'}) : ()),
       %$properties);
    if ($options{'hide_on_delete'}) {
      $dialog->signal_connect (delete_event => \&Gtk2::Widget::hide_on_delete);
    }
  }

  #   if (! $dialog->visible) {
  #     if (my $func = $options{'newly_visible_func'}) {
  #       $func->($dialog);
  #     }
  #   }
  $dialog->present;
  return $dialog;
}

sub _screen {
  my ($obj) = @_;
  if (! defined $obj) {
    return Gtk2::Gdk::Screen->get_default;
  }
  # don't want $display->get_screen($screennum)
  if ($obj->isa('Gtk2::Gdk::Display')) {
    return $obj->get_default_screen;
  }
  if (my $func = $obj->can('get_screen')) {
    return $obj->$func || croak "No screen for target $obj";
  }
  if (my $func = $obj->can('get_default_screen')) {
    return $obj->$func || croak "No default screen for target $obj";
  }
  return $obj;
}

sub _object_properties_equal {
  my ($obj, $properties) = @_;
  while (my ($pname, $value) = each %$properties) {
    my $pspec = $obj->find_property ($pname)
      || croak "No such property '",$pname,"'";
    if ($pspec->values_cmp ($value, $obj->get($pname)) != 0) {
      return 0;
    }
  }
  return 1;
}

1;
__END__

=for stopwords Ryde Chart

=head1 NAME

App::Chart::Gtk2::Ex::ToplevelBits -- helpers for Gtk2::Window toplevel widgets

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::ToplevelBits;

=head1 FUNCTIONS

=over 4

=item C<< $toplevel = App::Chart::Gtk2::Ex::ToplevelBits::popup ($class, key => value, ...) >>

Create or raise a dialog.

=over

=item C<< screen => $screen >>

=item C<< screen => $widget >>

=item C<< screen => $display >>

The screen on which the dialog should appear, either an existing dialog on
that screen or by creating a new one on it.

=item C<< properties => $hashref >>

Property settings an existing dialog must have, or to be applied on a newly
created dialog.

=item C<< transient_for => $toplevel >>

Set the dialog's C<transient-for> property to the given toplevel
C<Gtk2::Window>.  This normally makes the window manager keep the dialog on
top of the C<$toplevel>.

=item C<< modal => $bool >>

Set the dialog to modal, or not.  Modal forces the user to interact only
with this window or dialog, not any of the other application windows.

=item C<< hide_on_delete => $bool >>

When creating a new dialog, make it do a C<< $dialog->hide >> on a "delete"
request from the window manager.  This is done in the usual way by
connecting C<Gtk2::Widget::hide_on_delete> as a handler for the
C<delete-event> signal.  The default is to destroy the dialog on delete.

=back

=back

=head1 SEE ALSO

L<Gtk2::Window>, L<Gtk2::Dialog>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010 Kevin Ryde

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
