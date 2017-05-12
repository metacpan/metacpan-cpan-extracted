# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# Chart is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::Ex::WidgetPointerGrab;
use 5.008;
use strict;
use warnings;
use Carp;
use App::Chart::Glib::Ex::MoreUtils;

sub new_pointer_grab {
  my ($class, $widget, $owner_events, $event_mask, $confine_to, $cursor, $time)
    = @_;
  my $window = $widget->window
    || croak "Cannot grab pointer for unrealized widget\n";

  my $status = $window->pointer_grab
    ($window, $owner_events, $event_mask, $confine_to, $cursor, $time);
  if ($status ne 'success') {
    return $status;
  }

  my $self = bless { widget => $widget,
                     time => $time
                   }, $class;
  require Scalar::Util;
  Scalar::Util::weaken ($self->{'widget'});

  require Glib::Ex::SignalIds;
  $self->{'broken_id'} = Glib::Ex::SignalIds->new
    ($widget,
     $widget->signal_connect ('grab_broken_event', \&_do_grab_broken,
                              App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));

  return $self;
}

sub _do_grab_broken {
  my ($widget, $event, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  delete $self->{'widget'};
  delete $self->{'broken_ids'};
}

sub ungrab {
  my ($self) = @_;
  if (my $widget = delete $self->{'widget'}) {
    my $display = $widget->get_display;
    $display->pointer_ungrab ($self->{'time'});

    delete $self->{'broken_ids'};
  }
}

sub DESTROY {
  my ($self) = @_;
  ungrab ($self);
}

1;
__END__

=for stopwords Gdk WidgetPointerGrab

=head1 NAME

App::Chart::Gtk2::Ex::WidgetPointerGrab -- active pointer grab for widget

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::WidgetPointerGrab;

 # grab as a perl object
 my $grab = App::Chart::Gtk2::Ex::WidgetPointerGrab->new_pointer_grab
   # (many args ...);

=head1 DESCRIPTION

C<App::Chart::Gtk2::Ex::WidgetPointerGrab> is an object-oriented wrapper around the Gdk
pointer grab mechanism.  It automatically removes a grab when the
WidgetPointerGrab object is destroyed.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::WidgetPointerGrab->new_pointer_grab (...) >>

=back

=head1 SEE ALSO

L<Gtk2::Gdk::Window>

=cut
