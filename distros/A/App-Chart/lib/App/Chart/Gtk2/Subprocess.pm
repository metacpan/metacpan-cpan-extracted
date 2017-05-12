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

package App::Chart::Gtk2::Subprocess;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib 1.220;
use Gtk2;
use Gtk2::Ex::TreeModelBits;
use List::Util;
use POSIX qw(EWOULDBLOCK);
use Locale::TextDomain ('App-Chart');

use Glib::Ex::FreezeNotify;
use App::Chart::Glib::Ex::MoreUtils;
use Glib::Ex::SourceIds;
use App::Chart;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant { MAX_RUNNING          => 3,
               IDLE_TIMEOUT_SECONDS => 60,
               DEFAULT_STATUS       => '' };

use Glib::Object::Subclass
  'Glib::Object',
  signals => { notify => \&_do_notify,
               status_changed => { param_types => [ 'Glib::String' ],
                                   return_type => undef },
             },
  properties => [Glib::ParamSpec->string
                 ('status',
                  'status',
                  'Blurb.',
                  '',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->object
                 ('job',
                  'job',
                  'Blurb.',
                  # actually 'App::Chart::Gtk2::Job', but saying that
                  # creates package load order headaches
                  'Glib::Object',
                  Glib::G_PARAM_READWRITE),
                ];


our $store = Gtk2::ListStore->new ('Glib::Scalar');

sub INIT_INSTANCE {
  my ($self) = @_;
  ### Subprocess INIT_INSTANCE()

  $self->{'status'} = DEFAULT_STATUS;
  liststore_append_with_values ($store, 0 => $self);

  # or maybe $^X for '/usr/bin/perl' and $0 for 'chart', except that bombs
  # badly if being run from a script
  my @cmd = ('chart', '--subprocess');
  if ($App::Chart::option{'verbose'}) { push @cmd, '--verbose' }

  require IO::Socket;
  my ($sock_child, $sock_parent) = IO::Socket->socketpair
    (Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0);

  ### @cmd
  require Proc::SyncExec;
  my $pid = Proc::SyncExec::sync_exec
    (sub {
       my $fd = $sock_child->fileno;
       return POSIX::dup2 ($fd, 0) != -1
         &&   POSIX::dup2 ($fd, 1) != -1
           && POSIX::dup2 ($fd, 2) != -1;
     }, @cmd);
  #     }, '/bin/sh', '-c', 'echo hi 1>&2; sleep 5; echo bye');
  if (! defined $pid) {
    my $err = Glib::strerror ($!);
    my $status = $self->{'status'}
      = __x('Cannot start subprocess: {strerror}', strerror => $err);
    $self->message ("$status\n");
    return;
  }
  require App::Chart::Proc::ChildPid;
  $self->{'pidobj'} = App::Chart::Proc::ChildPid->new ($pid);

  $sock_child->close;
  $sock_parent->blocking(0);
  ### self: "$self"
  ### $pid
  ### reader fd: $sock_parent->fileno

  require PerlIO::via::EscStatus::Parser;
  $self->{'status_parser'} = PerlIO::via::EscStatus::Parser->new;
  $self->{'sock'} = $sock_parent;
  $self->{'io_watch'} = Glib::Ex::SourceIds->new
    (Glib::IO->add_watch ($sock_parent->fileno, ['in', 'hup', 'err'],
                          \&_do_read, App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  ### Subprocess FINALIZE_INSTANCE()
  $self->stop;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'job') {
    _update_idle_timer ($self);
  }
}

# 'notify' signal class closure
sub _do_notify {
  my ($self, $pspec) = @_;
  ### Subprocess notify: $pspec->get_name
  $self->signal_chain_from_overridden ($pspec);

  # emit 'status-changed' under notify so it's held up by freeze_notify
  if ($pspec->get_name eq 'status') {
    $self->signal_emit ('status-changed', $self->{'status'});
    _emit_row_changed ($self);
  }
}

sub pid {
  my ($self) = @_;
  my $pidobj = $self->{'pidobj'};
  return $pidobj && $pidobj->pid;
}

sub message {
  my ($self, $str) = @_;
  if (my $job = $self->{'job'}) {
    $job->message ($str);
  } else {
    print $str;
  }
}

sub start_job {
  my ($self, $job) = @_;
  ### Subprocess start_job(): "$job"
  {
    my $freezer = Glib::Ex::FreezeNotify->new ($self, $job);
    $job->set (subprocess => $self);
    $self->set (job => $job);

    my $fh = $self->{'sock'};
    if ($fh) {
      $job->set(status => __('Starting'));
      $self->set (status => __x('Running job: {name}',
                                name => $job->get('name')));
      undef $freezer;
      require Storable;
      my $data = Storable::freeze ($job->get('args'));
      print $fh length($data),"\n",$data;
      $fh->flush;
    } else {
      _unset_job ($self, $self->{'status'}, $self->{'status'});
    }
  }
}

sub status {
  my ($self) = @_;
  return $self->{'status'};
}

# return an idle Subprocess, possibly newly started, or undef if the
# subprocess maximum has been reached
#
sub find_idle {
  my ($class) = @_;
  ### Subprocess find_idle()
  my @procs = grep { $_->pid }
    Gtk2::Ex::TreeModelBits::column_contents ($store, 0);
  if (my $proc = List::Util::first {$_->{'sock'} && ! $_->{'job'}} @procs) {
    return $proc;
  }
  if (@procs >= MAX_RUNNING) {
    return undef;
  }
  return $class->new;
}

sub _unset_job {
  my ($self, $job_status, $self_status) = @_;
  # freeze_notify so job and subprocess are both updated before
  # status-change stuff runs
  my $freezer = Glib::Ex::FreezeNotify->new ($self);
  if (my $job = $self->{'job'}) {
    $freezer->add ($job);
    $job->set (subprocess => undef,
               done       => 1,
               status     => $job_status);
  }
  $self->set (job => undef,
              status => $self_status);
}

sub stop {
  my ($self) = @_;
  ### Subprocess stop()
  delete $self->{'io_watch'};
  delete $self->{'sock'};
  delete $self->{'pidobj'};
  _unset_job ($self, undef, __('Stopped'));
}

sub _do_read {
  my ($fd, $conditions, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return Glib::SOURCE_REMOVE;
  #### Subprocess read: "$self"
  my $sock = $self->{'sock'};
  my $status = undef;

  for (;;) {
    my $buf;
    my $len = $sock->sysread ($buf, 8192);
    #### got: $len
    ### $!

    if (! $len) {
      if (! defined $len) {
        if ($! == EWOULDBLOCK) { last; }  # no more data for now
        my $errmsg = Glib::strerror ($!);
        $self->message ("Subprocess read error: $errmsg\n");
        $status = __('Read error');
      } else {
        # end of file, child closed pipe
        $status = __('Died');
      }
      delete $self->{'io_watch'};
      delete $self->{'sock'};
      delete $self->{'pidobj'};
      _unset_job ($self, $status, $status);
      return Glib::SOURCE_REMOVE;
    }

    my ($new_status, $message) = $self->{'status_parser'}->parse($buf);
    $self->message ($message);
    if (defined $new_status) { $status = $new_status; }
  }

  if (defined $status) {
    if ($status eq 'Idle') {
      _unset_job ($self, __('Done'), __('Idle'));
      App::Chart::Gtk2::JobQueue->consider_run;
    } else {
      if (my $job = $self->{'job'}) {
        $job->set (status => $status);
      }
    }
  }
  return Glib::SOURCE_CONTINUE;
}

sub _update_idle_timer {
  my ($self) = @_;
  my $want_timer = ($self->pid && ! $self->{'job'});

  if ($want_timer) {
    $self->{'timer_ids'} ||= Glib::Ex::SourceIds->new
      (Glib::Timeout->add (IDLE_TIMEOUT_SECONDS * 1000,
                           \&_do_idle_timeout,
                           App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
  } else {
    $self->{'timer_ids'} = undef;
  }
}

sub _do_idle_timeout {
  my ($ref_weak_self) = @_;
  my $self = $$ref_weak_self || return Glib::SOURCE_REMOVE;
  $self->stop;

  Gtk2::Ex::TreeModelBits::remove_matching_rows
      ($store, sub { my ($store, $iter) = @_;
                     $store->get_value($iter,0) == $self });

  $self->{'timer_ids'} = undef;
  return Glib::SOURCE_REMOVE;
}

# send out a 'row-changed' on the global $store for subprocesses $self
sub _emit_row_changed {
  my ($self) = @_;
  $store->foreach (sub {
                     my ($store, $path, $iter) = @_;
                     my $this = $store->get_value ($iter, 0);
                     if ($this && $this == $self) {
                       $store->row_changed ($path, $iter);
                     }
                   });
}

sub all_subprocesses {
  my ($class) = @_;
  return Gtk2::Ex::TreeModelBits::column_contents ($store, 0);
}

sub remove_done {
  my ($class) = @_;
  Gtk2::Ex::TreeModelBits::remove_matching_rows
      ($store, sub { my ($store, $iter) = @_;
                     my $proc = $store->get_value ($iter, 0);
                     return ! $proc->pid;
                   });
}

#------------------------------------------------------------------------------
# generic helpers

sub liststore_append_with_values {
  my $store = shift;
  $store->insert_with_values ($store->iter_n_children(undef), @_);
}


1;
__END__

=for stopwords subprocess Storable stdout EINTR undef

=head1 NAME

App::Chart::Gtk2::Subprocess -- child process to run jobs

=head1 SYNOPSIS

 use App::Chart::Gtk2::Subprocess;
 my $subprocess = App::Chart::Gtk2::Subprocess->new;

=head1 DESCRIPTION

A C<App::Chart::Gtk2::Subprocess> is a child sub-process running C<chart
--subprocess>.  That subprocess reads tasks from its standard input (in a
length-delimited "Storable" format) and prints messages and
C<PerlIO::via::EscStatus> status strings to its stdout.  The
C<App::Chart::Gtk2::Subprocess> sends a C<App::Chart::Gtk2::Job> task to the subprocess
then reads its output.

C<App::Chart::Gtk2::Subprocess> notices if the child dies because the output pipe
closes.  It then waits that child with C<waitpid>.
C<< Glib::Child->watch_add >> is not used because in single thread mode it's
implemented with a non-restart C<sigaction> to stop the main loop poll, and
it's a bit worrying to think how much third-party library code might not
cope gracefully with EINTR.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Subprocess->new (key=>value,...) >>

Create and return a new subprocess.  The process is running, but idle.

=item C<< $subprocess->start_job ($job) >>

Start a C<App::Chart::Gtk2::Job> on C<$subprocess>.  C<$subprocess> must be idle.
This is meant for use by C<App::Chart::Gtk2::JobQueue>.

=item C<< $subprocess->pid() >>

Return the process ID of C<$subprocess>, or undef if no longer running.

=item C<< $subprocess->stop() >>

Forcibly stop the process and any job running in it.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Job>

=cut
