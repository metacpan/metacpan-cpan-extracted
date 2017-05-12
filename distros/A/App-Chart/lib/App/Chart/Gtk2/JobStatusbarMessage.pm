# show final status of a job as a MessageUntilKey or something




# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

package App::Chart::Gtk2::JobStatusbarMessage;
use 5.008;
use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
#use Smart::Comments;

use App::Chart::Glib::Ex::MoreUtils;
use Gtk2::Ex::Statusbar::Message;
use App::Chart::Gtk2::Job;

use Glib::Object::Subclass
  'Gtk2::Ex::Statusbar::Message',
  properties => [ Glib::ParamSpec->scalar
                  ('jobs',
                   'jobs',
                   'Arrayref of App::Chart::Gtk2::Job objects to display.',
                   Glib::G_PARAM_READWRITE)
                ];

# ENHANCE-ME: ConnectProperties onto the first in @$jobs, plus noticing when
# it and other jobs are done to remove from list

sub INIT_INSTANCE {
  my ($self) = @_;
  # disconnected in _do_job_status_changed() below when notice weakened away
  #   App::Chart::Gtk2::Job->signal_add_emission_hook
  #       ('status_changed',
  #        \&_do_job_status_changed,
  #        App::Chart::Glib::Ex::MoreUtils::ref_weak($self));

  require App::Chart::Glib::Ex::EmissionHook;
  $self->{'hook'} = App::Chart::Glib::Ex::EmissionHook->new
    ('App::Chart::Gtk2::Job',
     status_changed => \&_do_job_status_changed,
     App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;
  if ($pname eq 'jobs') {
    _update_status ($self);
  }
}

sub add_job {
  my ($self, $job) = @_;
  my $jobs = $self->{'jobs'};
  push @$jobs, $job;
  if (@$jobs == 1) {
    _update_status ($self);
  }
  $self->notify('jobs');
}

sub _do_job_status_changed {
  my ($invocation_hint, $param_list, $ref_weak_self) = @_;
  ### JobStatusbarMessage _do_job_status_changed()
  my ($job) = @$param_list;
  my $self = $$ref_weak_self || return 0; # destroyed, disconnect

  my $jobs = $self->{'jobs'};
  if (defined $jobs->[0] && $job == $jobs->[0]) {
    @$jobs = grep {! $_->is_done} @$jobs;
    # FIXME:
    # $self->notify('jobs'); 
    _update_status ($self);
  }
  return 1; # stay connected
}

sub _update_status {
  my ($self) = @_;
  ### JobStatusbarMessage _update_status()
  my $job = $self->{'jobs'}->[0];
  $self->set_message ($job ? $job->status : undef);
}

1;
__END__

=head1 NAME

App::Chart::Gtk2::JobStatusbarMessage -- display Job status in a Gtk2::Statusbar

=for test_synopsis my ($statusbar, $job)

=head1 SYNOPSIS

 use App::Chart::Gtk2::JobStatusbarMessage;
 my $msg = App::Chart::Gtk2::JobStatusbarMessage->new (statusbar => $statusbar);
 $msg->add_job ($job);

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::JobStatusbarMessage> is a subclass of
C<Gtk2::Ex::Statusbar::Message>.

    Glib::Object
      Gtk2::Ex::Statusbar::Message
        App::Chart::Gtk2::JobStatusbarMessage

=head1 DESCRIPTION

...

=head1 PROPERTIES

=over 4

=item C<jobs> ...

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Job>, L<App::Chart::Gtk2::JobQueue>

L<Gtk2::Statusbar>, L<Gtk2::Ex::Statusbar::Message>

=cut

