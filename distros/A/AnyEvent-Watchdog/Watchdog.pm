=head1 NAME

AnyEvent::Watchdog - generic watchdog/program restarter

=head1 SYNOPSIS

   # MUST be use'd as the very first thing in the main program,
   # as it clones/forks the program before it returns.
   use AnyEvent::Watchdog;

=head1 DESCRIPTION

This module implements a watchdog that can repeatedly fork the program and
thus effectively restart it - as soon as the module is use'd, it will fork
the program (if possible) and continue to run it normally in the child,
while the parent becomes a supervisor.

The child can then ask the supervisor to restart itself instead of
exiting, or ask the supervisor to restart it gracefully or forcefully.

B<NOTE:> This module B<< I<MUST> >> be used as the first thing in the main
program. It will cause weird effects when used from another module, as
perl does not expect to be forked inside C<BEGIN> blocks.

=head1 RECIPES

Use AnyEvent::Watchdog solely as a convenient on-demand-restarter:

   use AnyEvent::Watchdog;

   # and whenever you want to restart (e.g. to upgrade code):
   use AnyEvent::Watchdog::Util;
   AnyEvent::Watchdog::Util::restart;

Use AnyEvent::Watchdog to kill the program and exit when the event loop
fails to run for more than two minutes:

   use AnyEvent::Watchdog autorestart => 1, heartbeat => 120;

Use AnyEvent::Watchdog to automatically kill (but not restart) the program when it fails
to handle events for longer than 5 minutes:

   use AnyEvent::Watchdog heartbeat => 300;

=head1 VARIABLES/FUNCTIONS

This module is controlled via the L<AnyEvent::Watchdog::Util> module:

   use AnyEvent::Watchdog::Util;

   # attempt restart
   AnyEvent::Watchdog::Util::restart;

   # check if it is running
   AnyEvent::Watchdog::Util::enabled
      or croak "not running under watchdog!";

=cut

package AnyEvent::Watchdog;

# load modules we will use later anyways
use common::sense;

use Carp ();

our $VERSION = '1.0';

our $PID; # child pid
our $ENABLED = 0; # also version
our $AUTORESTART; # actually exit
our ($P, $C);

sub poll($) {
   (vec my $v, fileno $P, 1) = 1;
   CORE::select $v, undef, undef, $_[0]
}

sub server {
   my $expected;# do we expect a program exit?
   my $heartbeat;

   $AUTORESTART = 0;

   local $SIG{HUP}  = 'IGNORE';
   local $SIG{INT}  = 'IGNORE';
   local $SIG{TERM} = 'IGNORE';

   while () {
      if ($heartbeat) {
         unless (poll $heartbeat) {
            $expected = 1;
            warn "AnyEvent::Watchdog: heartbeat failed. killing.\n";
            kill 9, $PID;
            last;
         }
      }

      sysread $P, my $cmd, 1
         or last;

      if ($cmd eq chr 0) {
         $AUTORESTART = 0;

      } elsif ($cmd eq chr 1) {
         $AUTORESTART = 1;

      } elsif ($cmd eq chr 2) {
         sysread $P, my $timeout, 1
            or last;

         $timeout = ord $timeout;

         unless (poll $timeout) {
            warn "AnyEvent::Watchdog: program attempted restart, but failed to do so within $timeout seconds. killing.\n";
            kill 9, $PID;
         }

         if (sysread $P, my $dummy, 1) {
            warn "AnyEvent::Watchdog: unexpected program output. killing.\n";
            kill 9, $PID;
         }

         $expected = 1;
         last;

      } elsif ($cmd eq chr 3) {
         sysread $P, my $interval, 1
            or last;

         $heartbeat = ord $interval;

      } elsif ($cmd eq chr 4) {
         # heartbeat
         # TODO: should only reset heartbeat timeout with \005

      } else  {
         warn "AnyEvent::Watchdog: unexpected program output. killing.\n";
         kill 9, $PID;
         last;
      }
   }

   waitpid $PID, 0;

   require POSIX;

   my $termsig = POSIX::WIFSIGNALED ($?) && POSIX::WTERMSIG ($?);

   if ($termsig == POSIX::SIGINT () || $termsig == POSIX::SIGTERM ()) {
      $AUTORESTART = 0;
      $expected = 1;
   }

   unless ($expected) {
      warn "AnyEvent::Watchdog: program exited unexpectedly with status $?.\n"
         if $? >> 8;
   }

   if ($AUTORESTART) {
      warn "AnyEvent::Watchdog: attempting automatic restart.\n";
   } else {
      if ($termsig) {
         $SIG{$_} = 'DEFAULT' for keys %SIG;
         kill $termsig, $$;
         POSIX::_exit (127);
      } else {
         POSIX::_exit ($? >> 8);
      }
   }
}

our %SEEKPOS;
# due to bugs in perl, try to remember file offsets for all fds, and restore them later
# (the parser otherwise exhausts the input files)

# this causes perlio to flush its handles internally, so
# seek offsets become correct.
exec "."; # toi toi toi
#{
#   local $SIG{CHLD} = 'DEFAULT';
#   my $pid = fork;
#
#   if ($pid) {
#      waitpid $pid, 0;
#   } else {
#      kill 9, $$;
#   }
#}

# now record "all" fd positions, assuming 1023 is more than enough.
for (0 .. 1023) {
   open my $fh, "<&$_" or next;
   $SEEKPOS{$_} = (sysseek $fh, 0, 1 or next);
}

while () {
   if ($^O =~ /mswin32/i) {
      require AnyEvent::Util;
      ($P, $C) = AnyEvent::Util::portable_socketpair ()
         or Carp::croak "AnyEvent::Watchdog: unable to create restarter pipe: $!\n";
   } else {
      require Socket;
      socketpair $P, $C, Socket::AF_UNIX (), Socket::SOCK_STREAM (), 0
         or Carp::croak "AnyEvent::Watchdog: unable to create restarter pipe: $!\n";
   }

   local $SIG{CHLD} = 'DEFAULT';

   $PID = fork;

   unless (defined $PID) {
      warn "AnyEvent::Watchdog: '$!', retrying in one second...\n";
      sleep 1;
   } elsif ($PID) {
      # parent code
      close $C;
      server;
   } else {
      # child code
      $ENABLED = 1; # also version

      # restore seek offsets
      while (my ($k, $v) = each %SEEKPOS) {
         open my $fh, "<&$k" or next;
         sysseek $fh, $v, 0;
      }

      # continue the program normally
      close $P;
      last;
   }
}

sub import {
   shift;

   while (@_) {
      my $k = shift;

      require AnyEvent::Watchdog::Util;

      if ($k eq "autorestart") {
         AnyEvent::Watchdog::Util::autorestart (! ! shift);
      } elsif ($k eq "heartbeat") {
         AnyEvent::Watchdog::Util::heartbeat (shift || 60);
      } else {
         Carp::croak "AnyEvent::Watchdog: '$_' is not a valid import argument";
      }
   }
}

# used by AnyEvent::Watchdog::Util.
our $end;
END { $end && &$end }

=head1 SEE ALSO

L<AnyEvent::Watchdg::Util>, L<AnyEvent>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

