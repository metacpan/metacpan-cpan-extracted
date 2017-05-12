# Copyright 2007, 2008, 2009, 2010, 2011, 2016, 2017 Kevin Ryde

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

package App::Chart::Gtk2::Job;
use strict;
use warnings;
use Carp;
use Gtk2;
use POSIX qw(dup2 EWOULDBLOCK INT_MIN INT_MAX);
use Locale::TextDomain ('App-Chart');

use Glib::Ex::FreezeNotify;
use App::Chart;

# uncomment this to run the ### lines
# use Smart::Comments;

# Have had some trouble with segvs during exit
# 
#     

use Glib::Object::Subclass
  'Glib::Object',
  signals => { notify => \&_do_notify,
               message => { param_types => ['Glib::String'],
                            return_type => undef },
               status_changed => { param_types => ['Glib::String'],
                                   return_type => undef },
             },
  properties => [Glib::ParamSpec->int
                 ('priority',
                  'Priority',
                  'The priority of this job.',
                  INT_MIN, INT_MAX,
                  0, # default
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('name',
                  'Job name',
                  'Blurb.',
                  '',
                  Glib::G_PARAM_READWRITE),

                 # various nested perl array
                 Glib::ParamSpec->scalar
                 ('args',
                  'Job arguments',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('status',
                  'Status',
                  'Blurb.',
                  '',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->object
                 ('subprocess',
                  'Subprocess',
                  'Blurb.',
                  # actually 'App::Chart::Gtk2::Subprocess', but saying that
                  # creates package load order headaches
                  'Glib::Object',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->boolean
                 ('done',
                  'Done',
                  'Blurb.',
                  0,
                  Glib::G_PARAM_READWRITE),

                ];


#------------------------------------------------------------------------------

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'status'} = '';
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  $self->stop;
}

# 'notify' signal class closure
sub _do_notify {
  my ($self, $pspec) = @_;
  ### Job _do_notify(): $pspec->get_name

  $self->signal_chain_from_overridden ($pspec);

  # emit 'status-changed' under notify so it's held up by freeze_notify
  if ($pspec->get_name eq 'status') {
    ### Job emit status-changed ...
    $self->signal_emit ('status-changed', $self->{'status'});
  }
}

sub priority {
  my ($self) = @_;
  return $self->get('priority');
}
sub status {
  my ($self) = @_;
  return $self->{'status'};
}

sub delete {
  my ($self) = @_;
  $self->stop;
  App::Chart::Gtk2::JobQueue->remove_job ($self);
}

sub start {
  my ($class, @params) = @_;
  ### Job start()
  ### @params

  my $self = $class->new (@params);
  require App::Chart::Gtk2::JobQueue;
  App::Chart::Gtk2::JobQueue->enqueue ($self);
  return $self;
}

sub stop {
  my ($self) = @_;
  ### Job stop()
  my $freezer = Glib::Ex::FreezeNotify->new ($self);
  if (my $proc = $self->{'subprocess'}) {
    $freezer->add ($proc);
    $proc->stop;  # will remove itself from our 'subprocess' property
  }
  $self->set (done => 1,
              status => __('Stopped'));
}
sub is_stoppable {
  my ($self) = @_;
  return defined $self->{'subprocess'};
}
sub is_done {
  my ($self) = @_;
  return ! defined $self->{'subprocess'};
}

sub message {
  my ($self, $str) = @_;
  if ($str eq '') { return; }
  ### Job message: "$self  \"$str\""
  $self->signal_emit ('message', $str);
}

sub type {
  return 'Job';
}


1;
__END__

=head1 NAME

App::Chart::Gtk2::Job -- download job object

=head1 SYNOPSIS

 use App::Chart::Gtk2::Job;

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Job->start (key=>value,...) >>

Start a new download job.

    args    array ref of command line arguments
    type    string

=item C<< $job->stop() >>

Stop C<$job>.

=item C<< $job->is_stoppable() >>

Return true if C<$job> is running, which means it can be stopped.

=item C<< $job->is_done() >>

Return true if C<$job> not running, but has finished, either successfully or
unsuccessfully.

=back

=head1 PROPERTIES

=over 4

=item C<name> (integer)

...

=item C<args> (arrayref of strings, create-only)

...

=item C<priority> (integer)

...

=item C<status> (string)

A free-form string describing the status of the job.  For example while in
the job queue it's "Waiting", and later if finished successfully then "Done".

=back

=cut

