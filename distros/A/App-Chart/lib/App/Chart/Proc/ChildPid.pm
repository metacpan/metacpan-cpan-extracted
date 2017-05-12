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

package App::Chart::Proc::ChildPid;
use strict;
use warnings;
use Carp;
use Time::HiRes;
use POSIX qw(WNOHANG ECHILD);

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my ($class, $pid) = @_;
  return bless { pid => $pid }, $class;
}

sub DESTROY {
  my ($self) = @_;
  ## no critic (RequireInitializationForLocalVars)
  local $?; # don't let waitpid() clobber prospective exit code during exit()

  ### ChildPid DESTROY
  $self->kill_and_wait ('TERM');
}

sub pid {
  my ($self) = @_;
  return $self->{'pid'};
}

# sub poll {
#   my ($self) = @_;
#   return $self->kill(0) == 1;
# }

sub kill_and_wait {
  my ($self, $sig) = @_;
  if (! $self->{'pid'}) {
    $! = ECHILD;
    return -1;
  }
  if ($self->kill ($sig) != 1) { return -1; }
  Time::HiRes::usleep (10000);
  my $sleeps = 0;
  for (;;) {
    my $status = $self->wait (WNOHANG);
    if ($status != 0) { return $status; }
    if ($sleeps >= 3) { last; }
    sleep 1;
    $sleeps++;
  }
  if ($self->kill ('KILL') != 1) { return -1; }
  return $self->wait;
}

sub kill {
  my ($self, $sig) = @_;
  my $pid = $self->{'pid'} || return 0;
  if (! defined $sig) { $sig = 'TERM'; }
  return kill ($sig, $pid);
}

sub wait {
  my ($self, $flags) = @_;
  my $pid = delete $self->{'pid'}
    || do { $! = ECHILD; return -1; };
  if (! defined $flags) { $flags = 0; }
  ### ChildPid wait: $pid
  return waitpid ($pid, $flags);
}

1;
__END__

=head1 NAME

App::Chart::Proc::ChildPid -- child subprocess pid object

=for test_synopsis my ($pid)

=head1 SYNOPSIS

 use App::Chart::Proc::ChildPid;
 my $cp = App::Chart::Proc::ChildPid->new ($pid);
 $cp->kill_and_wait;

=head1 DESCRIPTION

C<App::Chart::Proc::ChildPid> keeps hold of a process ID which is a child of the
current process.  If the ChildPid object is destroyed the child is killed
and waited, thus protecting against creation of zombies.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Proc::ChildPid->new ($pid) >>

Create and return a new ChildPid holding process ID C<$pid>.  There's no
check that C<$pid> is actually a child of the current process.

=item C<< $cp->kill () >>

=item C<< $cp->kill ($sig) >>

Do a C<kill> on the child process, sending it C<SIGTERM> or the given signal
C<$sig> (a signal name or number).  The return is as per the core C<kill>
function, ie. 1 if successful, or 0 if no processes signalled (because the
child has been waited).

=item C<< $cp->wait() >>

Do a C<wait> on the child process and return its exit status.  If the child
has already been waited the return is -1 with C<$!> set to C<ECHILD> (no
such child).

=item C<< $cp->kill_and_wait() >>

Do a C<kill> and C<wait> combination on the child process and return its
exit status.  A C<SIGTERM> is sent first, and if that doesn't kill the
process after a few seconds a C<SIGKILL> is sent (which it can't ignore).

If the child has already been waited the return is -1 with C<$!> set to
C<ECHILD> (no such child).

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Subprocess>

=cut
