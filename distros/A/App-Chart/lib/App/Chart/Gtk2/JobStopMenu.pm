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

package App::Chart::Gtk2::JobStopMenu;
use 5.008;
use strict;
use warnings;
use Gtk2;
# use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use Glib::Ex::SignalIds;
use App::Chart;
use App::Chart::Gtk2::Job;


use Glib::Object::Subclass
  'Gtk2::Menu',
  properties => [ Glib::ParamSpec->object
                  ('job',
                   'job',
                   'App::Chart::Gtk2::Job object to act on, or undef.',
                   'App::Chart::Gtk2::Job',
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
  {
    my $item = $self->{'delete'}
      = Gtk2::ImageMenuItem->new_from_stock ('gtk-delete');
    $self->append ($item);
    $item->signal_connect (activate => \&_do_delete);
    $item->show;
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'job') {
    my $job = $newval;
    $self->{'job_ids'} = $job && Glib::Ex::SignalIds->new
      ($job,
       $job->signal_connect ('notify::status' => \&_do_job_status_change,
                             App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
    _update_sensitive ($self);
  }
}

# "Stop" item activate
sub _do_stop {
  my ($item) = @_;
  my $self = $item->get_toplevel;
  if (my $job = $self->{'job'}) {
    $job->stop;
  }
}

# "Delete" item activate
sub _do_delete {
  my ($item) = @_;
  my $self = $item->get_toplevel;
  if (my $job = $self->{'job'}) {
    $job->delete;
  }
}

# 'notify::status' on current job (if any)
sub _do_job_status_change {
  my ($job, $pspec, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  _update_sensitive ($self);
}

sub _update_sensitive {
  my ($self) = @_;
  my $job = $self->{'job'};

  my $stop = $self->{'stop'};
  $stop->set_sensitive ($job && $job->is_stoppable);

  my $delete = $self->{'delete'};
  $delete->set_sensitive ($job && $job->is_done);
}

sub popup_from_treeview {
  my ($self, $event, $treeview) = @_;

  my ($path) = $treeview->get_path_at_pos ($event->x, $event->y);
  if (! $path) { return; }

  my $model = $treeview->get_model;  # App::Chart::Gtk2::JobQueue
  my $iter = $model->get_iter ($path);
  my $job = $model->get_value ($iter, 0);
  $self->set (job => $job);
  $self->set_screen ($treeview->get_screen);
  $self->popup (undef, undef, undef, undef, $event->button, $event->time);
}

1;
__END__

=for stopwords undef

=head1 NAME

App::Chart::Gtk2::JobStopMenu -- menu to stop or delete a Job

=for test_synopsis my ($event, $treeview)

=head1 SYNOPSIS

 use App::Chart::Gtk2::JobStopMenu;
 my $menu = App::Chart::Gtk2::JobStopMenu->new;

 $menu->popup_from_treeview ($event, $treeview);

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::JobStopMenu> is a subclass of C<Gtk::Menu>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            App::Chart::Gtk2::JobStopMenu

=head1 DESCRIPTION

A C<App::Chart::Gtk2::JobStopMenu> displays a little menu to stop or delete a given
C<App::Chart::Gtk2::Job>.

    +--------+
    +--------+
    | Stop   |
    +--------+
    | Delete |
    +--------+

This is used by C<App::Chart::Gtk2::DownloadDialog> and has been split out to
reduce the amount of code there.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::JobStopMenu->new (key=>value,...) >>

Create and return a new C<App::Chart::Gtk2::JobStopMenu> object.  Optional
key/value pairs set initial properties as per C<< Glib::Object->new >>.

=back

=head1 PROPERTIES

=over 4

=item C<job> (C<App::Chart::Gtk2::Job>, default undef)

The job to be acted on by the menu.  Normally this is set at the time the
menu is popped up.  Changing it while popped up works, but could confuse the
user.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Job>, L<Gtk2::Menu>, L<App::Chart::Gtk2::DownloadDialog>

=cut
