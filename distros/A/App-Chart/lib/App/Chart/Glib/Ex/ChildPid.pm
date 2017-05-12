# SIGCHLD without SA_RESTART to interrupt poll() is probably a bit dangerous
# on slack library code



# Copyright 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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


package App::Chart::Glib::Ex::ChildPid;
use 5.008;
use strict;
use warnings;
use Glib;
use Carp;
use Time::HiRes;
use POSIX ();

use Glib::Ex::SourceIds;
use App::Chart::Glib::Ex::MoreUtils;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Glib::Object',
  signals => { exited => { param_types => ['Glib::Int'],
                           return_type => undef },
             },
  properties => [ Glib::ParamSpec->int
                  ('pid',
                   'pid',
                   'Blurb.',
                   0, POSIX::INT_MAX(), # range
                   0,                   # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('exited',
                   'exited',
                   'Blurb.',
                   0, # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('kill-on-destroy',
                   'kill-on-destroy',
                   'Blurb.',
                   1, # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->float
                  ('terminate-timeout',
                   'terminate-timeout',
                   'Blurb.',
                   0, POSIX::FLT_MAX(), # range
                   0,                   # default
                   Glib::G_PARAM_READWRITE),

                ];

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  if ($self->get('kill-on-destroy') && ! $self->{'exited'}) {
    $self->kill_and_wait;
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### ChildPid set: $pname
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'pid') {
    my $pid = $newval;
    $self->{'watch_ids'} = $pid && do {
      Glib::Ex::SourceIds->new
          (Glib::Child->watch_add ($pid, \&_do_child_watch,
                                   App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
    };

    $self->{'exited'} = 0;
    $self->notify ('exited');
  }
}

sub _do_child_watch {
  my ($pid, $status, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->{'exited'} = 1;
  $self->notify ('exited');
  $self->signal_emit ('exited', $status);
}

sub kill {
  my ($self, $sig) = @_;
  my $pid = $self->{'pid'} || return 0;
  if (! defined $sig) { $sig = 'TERM'; }
  return kill ($sig, $pid);
}

sub wait {
  my ($self, $flags) = @_;
  delete $self->{'watch_ids'};
  my $pid = delete $self->{'pid'}
    || do {
      ## no critic (RequireLocalizedPunctuationVars), it's an output
      $! = POSIX::ECHILD();
      return -1;
    };

  ### ChildPid wait: $pid
  my $status = waitpid ($pid, $flags || 0);
  if ($status != -1) {
    $self->{'exited'} = 1;
    $self->notify ('exited');
    $self->signal_emit ('exited', $status);
  }
  return $status;
}

sub kill_and_wait {
  my ($self, $sig) = @_;
  my $pid = $self->{'pid'};
  if (! $pid || $self->{'exited'}) {
    ## no critic (RequireLocalizedPunctuationVars), it's an output
    $! = POSIX::ECHILD();
    return -1;
  }
  if ($self->kill($sig) != 1) { return -1; }
  Time::HiRes::usleep (10000);
  my $sleeps = 0;
  for (;;) {
    my $status = $self->wait (POSIX::WNOHANG());
    if ($status != 0) { return $status; }
    if ($sleeps >= 3) { last; }
    sleep 1;
    $sleeps++;
  }
  if ($self->kill ('KILL') != 1) { return -1; }
  return $self->wait;
}

sub terminate_with_timeout {
  my ($self, $sig) = @_;
  my $pid = $self->{'pid'};
  if (! $pid || $self->{'exited'}) {
    ## no critic (RequireLocalizedPunctuationVars), it's an output
    $! = POSIX::ECHILD();
    return -1;
  }
  if (! defined $sig) { $sig = 'TERM'; }
  $self->{'terminate_sig'} = $sig;
  if ($self->kill($sig) != 1) {
    return -1;
  }

  $self->{'terminate_ids'} = Glib::Ex::SourceIds->new
    (Glib::Timeout->add ($self->get('terminate-timeout'),
                         \&_terminate_timeout,
                         App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
  return 1;
}
sub _terminate_timeout {
  my ($ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  my $sig = $self->{'terminate_sig'};

  if ($sig eq 'KILL' || $sig eq POSIX::SIGKILL()) {
    Glib::Log->warning (__PACKAGE__, 'child did not die with SIGKILL');

  } else {
    if ($sig eq 'TERM' || $sig eq POSIX::SIGTERM()) {
      $sig = 'KILL';
    } else {
      $sig = 'TERM';
    }
    $self->terminate_with_timeout ($sig);
  }

  return 0; # Glib::SOURCE_REMOVE
}

1;
__END__

=for stopwords subprocess SIGTERM boolean ChildPid SIGSTOP SIGTSTP

=head1 NAME

App::Chart::Glib::Ex::ChildPid -- object holding child process ID

=for test_synopsis my ($pid)

=head1 SYNOPSIS

 use App::Chart::Glib::Ex::ChildPid;
 my $pobj = App::Chart::Glib::Ex::ChildPid->new (pid => $pid);

 $pobj->kill ('INT');
 $pobj->terminate_with_timeout;

=head1 DESCRIPTION

A C<App::Chart::Glib::Ex::ChildPid> holds the process ID (an integer) for a child
process created by C<fork> or similar spawn.

The fork and subprocess emulation described in L<perlfork> doesn't work with
Glib process watching (as of Perl-Glib 1.200) and cannot be used with
C<App::Chart::Glib::Ex::ChildPid>.

=head1 FUNCTIONS

=over 4

=item C<< $pobj->kill () >>

=item C<< $pobj->kill ($sig) >>

Send signal C<$sig> to the C<$pobj> process.  C<$sig> defaults to SIGTERM,
otherwise it's a string or number per the core C<kill> function (see
L<perlfunc/kill>).

=item C<< $pobj->wait () >>

=item C<< $pobj->wait ($flags) >>

Block and wait for the C<$pobj> process to terminate, as per the core
C<waitpid>.  The C<exited> signal is also emitted in the usual way if it
terminates.

=back

=head1 PROPERTIES

=over 4

=item C<pid> (integer, default 0)

The process ID held and operated on.  It must be an immediate child of the
current process, but can be started by either C<fork> or any of the several
Perl fork/spawn/open modules.

=item C<exited> (boolean, default false)

The process ID held and operated on.  It must be an immediate child of the
current process, but can be started by either C<fork> or any of the several
Perl fork/spawn/open modules.

=item C<kill-on-destroy> (boolean, default true)

If true then when the ChildPid object is destroyed through garbage
collection the process is killed and waited if that hasn't already been
done.

This is true by default to ensure the child process stops when the parent
stops, or when you discard the object as no longer wanted.

=back

=head1 SIGNALS

=over 4

=item C<exited ($status)>

Emitted when the child process exits, either normally or killed by a signal,
but not when merely paused by SIGSTOP, SIGTSTP, etc.

This is implemented by a C<< Glib::Child->add_watch >> (see
L<Glib::MainLoop>).  Note that function uses C<SIGCHLD> and if you install
your own C<$SIG{'CHLD'}> handler then C<exited> won't run.

=back

=head1 SEE ALSO

L<Glib::MainLoop>, L<IPC::Open3>, L<Proc::SyncExec>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2016 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
