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

package App::Chart::Gtk2::SubprocessStopMenu;
use 5.010;
use strict;
use warnings;
use Carp;
use Glib::Ex::SignalIds;
use Gtk2;
use Scalar::Util;
# use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Gtk2::Subprocess;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Menu',
  properties => [ Glib::ParamSpec->object
                  ('subprocess',
                   'subprocess',
                   'App::Chart::Gtk2::Subprocess object to act on, or undef.',
                   'App::Chart::Gtk2::Subprocess',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  # avoid selecting Stop too easily
  $self->append (Gtk2::SeparatorMenuItem->new);

  {
    my $item = $self->{'stop'}
      = Gtk2::ImageMenuItem->new_from_stock ('gtk-stop');
    $self->append ($item);
    $item->signal_connect (activate => \&_do_stop);
    $item->show;
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'subprocess') {
    my $subprocess = $newval;
    $self->{'subprocess_ids'} = $subprocess && Glib::Ex::SignalIds->new
      ($subprocess,
       $subprocess->signal_connect ('notify::status',
                                    \&_do_subprocess_status_change,
                                    App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
    _update_sensitive ($self);
  }
}

# 'activate' from Stop item
sub _do_stop {
  my ($item) = @_;
  my $self = $item->get_ancestor(__PACKAGE__) || return;
  ### SubprocessStopMenu stop: "$self"
  ### subprocess: "@{[$self->{'subprocess'}//'undef']}"
  if (my $subprocess = $self->{'subprocess'}) {
    if (my $job = $subprocess->get('job')) {
      $job->stop;
    } else {
      $subprocess->stop;
    }
  }
}

# 'notify::status' from $self->{'subprocess'}, if any
sub _do_subprocess_status_change {
  my ($subprocess, $pspec, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  _update_sensitive ($self);
}

sub _update_sensitive {
  my ($self) = @_;
  my $subprocess = $self->{'subprocess'};

  my $stop = $self->{'stop'};
  $stop->set_sensitive ($subprocess && defined ($subprocess->pid));
}

sub popup_from_treeview {
  my ($self, $event, $treeview) = @_;
  ref $self or $self = $self->new;  # object or class method

  my ($path) = $treeview->get_path_at_pos ($event->x, $event->y);
  if (! $path) { return; }

  my $model = $treeview->get_model;  # $App::Chart::Gtk2::Subprocess::store
  my $iter = $model->get_iter ($path);
  my $subprocess = $model->get_value ($iter, 0);
  $self->set (subprocess => $subprocess);
  $self->set_screen ($treeview->get_screen);
  $self->popup (undef, undef, undef, undef, $event->button, $event->time);
}

1;
__END__

=for stopwords Subprocess undef subprocess

=head1 NAME

App::Chart::Gtk2::SubprocessStopMenu -- menu to stop or delete a Subprocess

=for test_synopsis my ($event, $treeview)

=head1 SYNOPSIS

 use App::Chart::Gtk2::SubprocessStopMenu;
 my $menu = App::Chart::Gtk2::SubprocessStopMenu->new;
 $menu->popup_from_treeview ($event, $treeview);

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::SubprocessStopMenu> is a subclass of C<Gtk::Menu>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            App::Chart::Gtk2::SubprocessStopMenu

=head1 DESCRIPTION

C<App::Chart::Gtk2::SubprocessStopMenu> displays a little menu to stop a given
C<App::Chart::Gtk2::Subprocess>.

    +--------+
    +--------+
    | Stop   |
    +--------+

This is used by C<App::Chart::Gtk2::DownloadDialog> and has been split out
to reduce the amount of code there.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::SubprocessStopMenu->new (key=>value,...) >>

Create and return a new C<App::Chart::Gtk2::SubprocessStopMenu> object.  Optional
key/value pairs set initial properties as per C<< Glib::Object->new >>.

=back

=head1 PROPERTIES

=over 4

=item C<subprocess> (C<App::Chart::Gtk2::Subprocess> object, default undef)

The subprocess to act on in the menu.  Normally this is set at the time the
menu is popped up.  Changing it while popped up works, but might confuse the
user.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Subprocess>, L<Gtk2::Menu>, L<App::Chart::Gtk2::DownloadDialog>

=cut
