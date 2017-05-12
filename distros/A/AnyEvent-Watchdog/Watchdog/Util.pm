=head1 NAME

AnyEvent::Watchdog::Util - watchdog control and process management

=head1 SYNOPSIS

   use AnyEvent::Watchdog::Util;

=head1 DESCRIPTION

This module can control the watchdog started by using
L<AnyEvent::Watchdog> in your main program, but it has useful
functionality even when not running under the watchdog at all, such as
program exit hooks.

=head1 VARIABLES/FUNCTIONS

The module supports the following variables and functions:

=over 4

=cut

package AnyEvent::Watchdog::Util;

# load modules we will use later anyways
use common::sense;
use AnyEvent ();
use Carp ();

our $VERSION = '1.0';

our $C;
BEGIN {
   *C = \$AnyEvent::Watchdog::C;
}

our $AUTORESTART;
our $HEARTBEAT_W;

=item AnyEvent::Watchdog::Util::enabled

Return true when the program is running under the regime of
AnyEvent::Watchdog, false otherwise.

   AnyEvent::Watchdog::Util::enabled
      or die "watchdog not enabled...";
   AnyEvent::Watchdog::Util::restart;

Note that if it returns defined, but false, then AnyEvent::Watchdog is
running, but you are in the watchdog process - you probably did something
very wrong in this case.

=cut

sub enabled() {
   $AnyEvent::Watchdog::ENABLED
}

=item AnyEvent::Watchdog::Util::restart_in [$timeout]

Tells the supervisor to restart the process when it exits (enable
autorestart), or forcefully after C<$timeout> seconds (minimum 1, maximum
255, default 60).

This function disables the heartbeat, if it was enabled. Also, after
calling this function the watchdog will ignore any further requests until
the program has restarted.

Good to call before you intend to exit, in case your clean-up handling
gets stuck.

=cut

sub restart_in(;$) {
   my ($timeout) = @_;

   return unless $C;

   undef $HEARTBEAT_W;

   $timeout =  60 unless defined $timeout;
   $timeout =   1 if $timeout <   1;
   $timeout = 255 if $timeout > 255;

   syswrite $C, "\x01\x02" . chr $timeout;

   # now make sure we dont' send it any further requests
   our $OLD_C = $C; undef $C;
}

=item AnyEvent::Watchdog::Util::restart [$timeout]

Just like C<restart_in>, but also calls C<exit 0>. This means that this is
the ideal method to force a restart.

=cut

sub restart(;$) {
   &restart_in;
   exit 0;
}

=item AnyEvent::Watchdog::Util::autorestart [$boolean]

=item use AnyEvent::Watchdog autorestart => $boolean

Enables or disables autorestart (initially disabled, default for
C<$boolean> is to enable): By default, the supervisor will exit if the
program exits or dies in any way. When enabling autorestart behaviour,
then the supervisor will try to restart the program after it dies.

Note that the supervisor will never autorestart when the child died with
SIGINT or SIGTERM.

=cut

sub autorestart(;$) {
   my $AUTORESTART = !@_ || $_[0];

   return unless $C;

   unless (enabled) {
      warn "AnyEvent::Watchdog: watchdog not running, cannot enable autorestart, ignoring.\n"
         if $AUTORESTART;

      $AUTORESTART = 0;

      return;
   }

   syswrite $C, $AUTORESTART ? "\x01" : "\x00";
}

=item AnyEvent::Watchdog::Util::heartbeat [$interval]

=item use AnyEvent::Watchdog heartbeat => $interval

Tells the supervisor to automatically kill the program if it doesn't
react for C<$interval> seconds (minium 1, maximum 255, default 60) , then
installs an AnyEvent timer the sends a regular heartbeat to the supervisor
twice as often.

Exit behaviour isn't changed, so if you want a restart instead of an exit,
you have to call C<autorestart>.

The heartbeat frequency can be changed as often as you want, an interval
of C<0> disables the heartbeat check again.

=cut

sub heartbeat(;$) {
   my ($interval) = @_;

   unless (enabled) {
      warn "AnyEvent::Watchdog: watchdog not running, cannot enable heartbeat, ignoring.\n";
      return;
   }

   $interval =  60 unless defined $interval;
   $interval =   0 if $interval <   0;
   $interval = 255 if $interval > 255;

   $interval = int $interval;

   syswrite $C, "\x03" . chr $interval
      if $C;

   $HEARTBEAT_W = AE::timer 0, $interval * 0.5, sub {
      syswrite $C, "\x04"
         if $C;
   };
}

=item AnyEvent::Watchdog::Util::on_exit { BLOCK; shift->() }

Installs an exit hook that is executed when the program is about to exit,
while event processing is still active to some extent.

The hook should do whatever it needs to do (close active connections,
disable listeners, write state, free resources etc.). When it is done, it
should call the code reference that has been passed to it.

This means you can install event handlers and return from the block, and
the program will not exit until the callback is invoked.

Exiting "the right way" is surprisingly difficult. This is what C<on_exit>
does:

It installs watchers for C<SIGTERM>, C<SIGINT>, C<SIGXCPU> and C<SIGXFSZ>,
and well as an C<END> block (the END block is actually registered
in L<AnyEvent::Watchdog>, if possible, so it executes as late as
possible). The signal handlers remember the signal and then call C<exit>,
invoking the C<END> callback.

The END block then checks for an exit code of C<255>, in which case
nothing happens (C<255> is the exit code that results from a program
error), otherwise it runs all C<on_exit> hooks and waits for their
completion using the event loop.

After all C<on_exit> hooks have finished, the program will either be
C<exit>ed with the relevant status code (if C<exit> was the cause for the
program exit), or it will reset the signal handler, unblock the signal and
kill itself with the signal, to ensure that the exit status is correct.

If the program is running under the watchdog, and autorestart is enabled,
then the heartbeat is disabled and the watchdog is told that the program
wishes to exit within C<60> seconds, after which it will be forcefully
killed.

All of this should ensure that C<on_exit> hooks are only executed when the
program is in a sane state and data structures are still intact. This only
works when the program does not install it's own TERM (etc.) watchers, of
course, as there is no control over them.

There is currently no way to unregister C<on_exit> hooks.

=cut

our @ON_EXIT;
our %SIG_W;
our $EXIT_STATUS; # >= 0 exit status; arrayref => signal, undef if exit was just called

# in case AnyEvent::Watchdog is not loaded, use our own END block
END { $AnyEvent::Watchdog::end && &$AnyEvent::Watchdog::end }

sub _exit {
   $EXIT_STATUS = $? unless defined $EXIT_STATUS;

   # we might have two END blocks trying to call us.
   undef $AnyEvent::Watchdog::end;

   if (enabled) {
      undef $HEARTBEAT_W;
      restart_in 60;
   }

   my $cv = AE::cv;
   my $cb = sub { $cv->end };

   $cv->begin;
   while (@ON_EXIT) {
      $cv->begin;
      (pop @ON_EXIT)->($cb);
   }
   $cv->end;
   $cv->recv;

   if (ref $EXIT_STATUS) {
      # signal
      # reset to default, hopefully this overrides any C-level handlers
      $SIG{$EXIT_STATUS->[0]} = 'DEFAULT';

      eval {
         # try to unblock
         require POSIX;

         my $set = POSIX::SigSet->new;
         $set->addset ($EXIT_STATUS->[1]);
         POSIX::sigprocmask (POSIX::SIG_UNBLOCK (), $set);
      };

      # now raise the signal
      kill $EXIT_STATUS->[1], $$;

      # well, if we can't force it even now, try exit 255
      $? = 255;
   } else {
      # exit status
      $? = $EXIT_STATUS;
   }

}

sub on_exit(&) {
   unless ($AnyEvent::Watchdog::end) {
      $AnyEvent::Watchdog::end = \&_exit;

      push @ON_EXIT, $_[0];

      for my $signal (qw(TERM INT XFSZ XCPU)) {
         my $signum = AnyEvent::Base::sig2num $signal
            or next;
         $SIG_W{$signum} = AE::signal $signal => sub {
            $EXIT_STATUS = [$signal => $signum];
            exit 124;
         };
      }
   }
}

=back

=head1 SEE ALSO

L<AnyEvent>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

