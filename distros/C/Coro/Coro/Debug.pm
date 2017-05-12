=head1 NAME

Coro::Debug - various functions that help debugging Coro programs

=head1 SYNOPSIS

 use Coro::Debug;

 our $server = new_unix_server Coro::Debug "/tmp/socketpath";

 $ socat readline unix:/tmp/socketpath

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module provides some debugging facilities. Most will, if not handled
carefully, severely compromise the security of your program, so use it
only for debugging (or take other precautions).

It mainly implements a very primitive debugger that is very easy to
integrate in your program:

   our $server = new_unix_server Coro::Debug "/tmp/somepath";
   # see new_unix_server, below, for more info

It lets you list running coroutines:

            state (rUnning, Ready, New or neither)
            |cctx allocated
            ||  resident set size (octets)
            ||  |   scheduled this many times
   > ps     ||  |   |
        PID SC  RSS USES Description              Where
   14572344 UC  62k 128k [main::]                 [dm-support.ext:47]
   14620056 -- 2260   13 [coro manager]           [Coro.pm:358]
   14620128 -- 2260  166 [unblock_sub scheduler]  [Coro.pm:358]
   17764008 N-  152    0 [EV idle process]        -
   13990784 -- 2596  10k timeslot manager         [cf.pm:454]
   81424176 --  18k 4758 [async pool idle]        [Coro.pm:257]
   23513336 -- 2624    1 follow handler           [follow.ext:52]
   40548312 --  15k 5597 player scheduler         [player-scheduler.ext:13]
   29138032 -- 2548  431 music scheduler          [player-env.ext:77]
   43449808 -- 2260 3493 worldmap updater         [item-worldmap.ext:115]
   33352488 --  19k 2845 [async pool idle]        [Coro.pm:257]
   81530072 --  13k  43k map scheduler            [map-scheduler.ext:65]
   30751144 --  15k 2204 [async pool idle]        [Coro.pm:257]

Lets you do backtraces on about any coroutine:

   > bt 18334288
   coroutine is at /opt/cf/ext/player-env.ext line 77
           eval {...} called at /opt/cf/ext/player-env.ext line 77
           ext::player_env::__ANON__ called at -e line 0
           Coro::_run_coro called at -e line 0

Or lets you eval perl code:

   > 5+7
   12

Or lets you eval perl code within other coroutines:

   > eval 18334288 caller(1); $DB::args[0]->method
   1

It can also trace subroutine entry/exits for most coroutines (those not
having recursed into a C function), resulting in output similar to:

   > loglevel 5
   > trace 94652688
   2007-09-27Z20:30:25.1368 (5) [94652688] enter Socket::sockaddr_in with (8481,\x{7f}\x{00}\x{00}\x{01})
   2007-09-27Z20:30:25.1369 (5) [94652688] leave Socket::sockaddr_in returning (\x{02}\x{00}...)
   2007-09-27Z20:30:25.1370 (5) [94652688] enter Net::FCP::Util::touc with (client_get)
   2007-09-27Z20:30:25.1371 (5) [94652688] leave Net::FCP::Util::touc returning (ClientGet)
   2007-09-27Z20:30:25.1372 (5) [94652688] enter AnyEvent::Impl::Event::io with (AnyEvent,fh,GLOB(0x9256250),poll,w,cb,CODE(0x8c963a0))
   2007-09-27Z20:30:25.1373 (5) [94652688] enter Event::Watcher::__ANON__ with (Event,poll,w,fd,GLOB(0x9256250),cb,CODE(0x8c963a0))
   2007-09-27Z20:30:25.1374 (5) [94652688] enter Event::io::new with (Event::io,poll,w,fd,GLOB(0x9256250),cb,CODE(0x8c963a0))
   2007-09-27Z20:30:25.1375 (5) [94652688] enter Event::Watcher::init with (Event::io=HASH(0x8bfb120),HASH(0x9b7940))

If your program uses the Coro::Debug::log facility:

   Coro::Debug::log 0, "important message";
   Coro::Debug::log 9, "unimportant message";

Then you can even receive log messages in any debugging session:

   > loglevel 5
   2007-09-26Z02:22:46 (9) unimportant message

Other commands are available in the shell, use the C<help> command for a list.

=head1 FUNCTIONS

None of the functions are being exported.

=over 4

=cut

package Coro::Debug;

use common::sense;

use overload ();

use Carp ();
use Scalar::Util ();

use Guard;

use AnyEvent ();
use AnyEvent::Util ();
use AnyEvent::Socket ();

use Coro ();
use Coro::Handle ();
use Coro::State ();
use Coro::AnyEvent ();
use Coro::Timer ();

our $VERSION = 6.511;

our %log;
our $SESLOGLEVEL = exists $ENV{PERL_CORO_DEFAULT_LOGLEVEL} ? $ENV{PERL_CORO_DEFAULT_LOGLEVEL} : -1;
our $ERRLOGLEVEL = exists $ENV{PERL_CORO_STDERR_LOGLEVEL}  ? $ENV{PERL_CORO_STDERR_LOGLEVEL}  : -1;

sub find_coro {
   my ($pid) = @_;

   if (my ($coro) = grep $_ == $pid, Coro::State::list) {
      $coro
   } else {
      print "$pid: no such coroutine\n";
      undef
   }
}

sub format_msg($$) {
   my ($time, $micro) = Coro::Util::gettimeofday;
   my ($sec, $min, $hour, $day, $mon, $year) = gmtime $time;
   my $date = sprintf "%04d-%02d-%02dZ%02d:%02d:%02d.%04d",
                      $year + 1900, $mon + 1, $day, $hour, $min, $sec, $micro / 100;
   sprintf "%s (%d) %s", $date, $_[0], $_[1]
}

sub format_num4($) {
   my ($v) = @_;

   return sprintf "%4d"   , $v                     if $v <  1e4;
   # 1e5 redundant
   return sprintf "%3.0fk", $v /             1_000 if $v <  1e6;
   return sprintf "%1.1fM", $v /         1_000_000 if $v <  1e7 * .995;
   return sprintf "%3.0fM", $v /         1_000_000 if $v <  1e9;
   return sprintf "%1.1fG", $v /     1_000_000_000 if $v < 1e10 * .995;
   return sprintf "%3.0fG", $v /     1_000_000_000 if $v < 1e12;
   return sprintf "%1.1fT", $v / 1_000_000_000_000 if $v < 1e13 * .995;
   return sprintf "%3.0fT", $v / 1_000_000_000_000 if $v < 1e15;

   "++++"
}

=item log $level, $msg

Log a debug message of the given severity level (0 is highest, higher is
less important) to all interested parties.

=item stderr_loglevel $level

Set the loglevel for logging to stderr (defaults to the value of the
environment variable PERL_CORO_STDERR_LOGLEVEL, or -1 if missing).

=item session_loglevel $level

Set the default loglevel for new coro debug sessions (defaults to the
value of the environment variable PERL_CORO_DEFAULT_LOGLEVEL, or -1 if
missing).

=cut

sub log($$) {
   my ($level, $msg) = @_;
   $msg =~ s/\s*$/\n/;
   $_->($level, $msg) for values %log;
   printf STDERR format_msg $level, $msg if $level <= $ERRLOGLEVEL;
}

sub session_loglevel($) {
   $SESLOGLEVEL = shift;
}

sub stderr_loglevel($) {
   $ERRLOGLEVEL = shift;
}

=item trace $coro, $loglevel

Enables tracing the given coroutine at the given loglevel. If loglevel is
omitted, use 5. If coro is omitted, trace the current coroutine. Tracing
incurs a very high runtime overhead.

It is not uncommon to enable tracing on oneself by simply calling
C<Coro::Debug::trace>.

A message will be logged at the given loglevel if it is not possible to
enable tracing.

=item untrace $coro

Disables tracing on the given coroutine.

=cut

sub trace {
   my ($coro, $loglevel) = @_;

   $coro ||= $Coro::current;
   $loglevel = 5 unless defined $loglevel;

   (Coro::async {
      if (eval { Coro::State::trace $coro, Coro::State::CC_TRACE | Coro::State::CC_TRACE_SUB; 1 }) {
         Coro::Debug::log $loglevel, sprintf "[%d] tracing enabled", $coro + 0;
         $coro->{_trace_line_cb} = sub {
            Coro::Debug::log $loglevel, sprintf "[%d] at %s:%d\n", $Coro::current+0, @_;
         };
         $coro->{_trace_sub_cb} = sub {
            Coro::Debug::log $loglevel, sprintf "[%d] %s %s %s\n",
               $Coro::current+0,
               $_[0] ? "enter" : "leave",
               $_[1],
               $_[2] ? ($_[0] ? "with (" : "returning (") . (
                  join ",",
                     map {
                        my $x = ref $_ ? overload::StrVal $_ : $_;
                        (substr $x, 40) = "..." if 40 + 3 < length $x;
                        $x =~ s/([^\x20-\x5b\x5d-\x7e])/sprintf "\\x{%02x}", ord $1/ge;
                        $x
                     } @{$_[2]}
               ) . ")" : "";
         };

         undef $coro; # the subs keep a reference which we do not want them to do
      } else {
         Coro::Debug::log $loglevel, sprintf "[%d] unable to enable tracing: %s", $Coro::current + 0, $@;
      }
   })->prio (Coro::PRIO_MAX);

   Coro::cede;
}

sub untrace {
   my ($coro) = @_;

   $coro ||= $Coro::current;

   (Coro::async {
      Coro::State::trace $coro, 0;
      delete $coro->{_trace_sub_cb};
      delete $coro->{_trace_line_cb};
   })->prio (Coro::PRIO_MAX);

   Coro::cede;
}

sub ps_listing {
   my $times = Coro::State::enable_times;
   my $flags = $1;
   my $verbose = $flags =~ /v/;
   my $desc_format = $flags =~ /w/ ? "%-24s" : "%-24.24s";
   my $tim0_format = $times ? " %9s %8s " : " ";
   my $tim1_format = $times ? " %9.3f %8.3f " : " ";
   my $buf = sprintf "%20s %s%s %4s %4s$tim0_format$desc_format %s\n",
                     "PID", "S", "C", "RSS", "USES",
                     $times ? ("t_real", "t_cpu") : (),
                     "Description", "Where";
   for my $coro (reverse Coro::State::list) {
      my @bt;
      Coro::State::call ($coro, sub {
         # we try to find *the* definite frame that gives most useful info
         # by skipping Coro frames and pseudo-frames.
         for my $frame (1..10) {
            my @frame = caller $frame;
            @bt = @frame if $frame[2];
            last unless $bt[0] =~ /^Coro/;
         }
      });
      $bt[1] =~ s/^.*[\/\\]// if @bt && !$verbose;
      $buf .= sprintf "%20s %s%s %4s %4s$tim1_format$desc_format %s\n",
                      $coro+0,
                      $coro->is_new ? "N" : $coro->is_running ? "U" : $coro->is_ready ? "R" : "-",
                      $coro->is_traced ? "T" : $coro->has_cctx ? "C" : "-",
                      format_num4 $coro->rss,
                      format_num4 $coro->usecount,
                      $times ? $coro->times : (),
                      $coro->debug_desc,
                      (@bt ? sprintf "[%s:%d]", $bt[1], $bt[2] : "-");
   }

   $buf
}

=item command $string

Execute a debugger command, sending any output to STDOUT. Used by
C<session>, below.

=cut

sub command($) {
   my ($cmd) = @_;

   $cmd =~ s/\s+$//;

   if ($cmd =~ /^ps (?:\s* (\S+))? $/x) {
      print ps_listing;

   } elsif ($cmd =~ /^bt\s+(\d+)$/) {
      if (my $coro = find_coro $1) {
         my $bt;
         Coro::State::call ($coro, sub {
            local $Carp::CarpLevel = 2;
            $bt = eval { Carp::longmess "coroutine is" } || "$@";
         });
         if ($bt) {
            print $bt;
         } else {
            print "$1: unable to get backtrace\n";
         }
      }

   } elsif ($cmd =~ /^(?:e|eval)\s+(\d+)\s+(.*)$/) {
      if (my $coro = find_coro $1) {
         my $cmd = eval "sub { $2 }";
         my @res;
         Coro::State::call ($coro, sub { @res = eval { &$cmd } });
         print $@ ? $@ : (join " ", @res, "\n");
      }

   } elsif ($cmd =~ /^(?:tr|trace)\s+(\d+)$/) {
      if (my $coro = find_coro $1) {
         trace $coro;
      }

   } elsif ($cmd =~ /^(?:ut|untrace)\s+(\d+)$/) {
      if (my $coro = find_coro $1) {
         untrace $coro;
      }

   } elsif ($cmd =~ /^cancel\s+(\d+)$/) {
      if (my $coro = find_coro $1) {
         $coro->cancel;
      }

   } elsif ($cmd =~ /^ready\s+(\d+)$/) {
      if (my $coro = find_coro $1) {
         $coro->ready;
      }

   } elsif ($cmd =~ /^kill\s+(\d+)(?:\s+(.*))?$/) {
      my $reason = defined $2 ? $2 : "killed";

      if (my $coro = find_coro $1) {
         $coro->throw ($reason);
      }

   } elsif ($cmd =~ /^enable_times(\s+\S.*)?\s*$/) {
      my $enable = defined $1 ? 1*eval $1 : !Coro::State::enable_times;

      Coro::State::enable_times $enable;

      print "per-thread real and process time gathering ", $enable ? "enabled" : "disabled", ".\n";

   } elsif ($cmd =~ /^help$/) {
      print <<EOF;
ps [w|v]                show the list of all coroutines (wide, verbose)
bt <pid>                show a full backtrace of coroutine <pid>
eval <pid> <perl>       evaluate <perl> expression in context of <pid>
trace <pid>             enable tracing for this coroutine
untrace <pid>           disable tracing for this coroutine
kill <pid> <reason>	throws the given <reason> string in <pid>
cancel <pid>		cancels this coroutine
ready <pid>		force <pid> into the ready queue
enable_times <enable>	enable or disable time profiling in ps
<anything else>         evaluate as perl and print results
<anything else> &       same as above, but evaluate asynchronously
                        you can use (find_coro <pid>) in perl expressions
                        to find the coro with the given pid, e.g.
                        (find_coro 9768720)->ready
EOF

   } elsif ($cmd =~ /^(.*)&$/) {
      my $cmd = $1;
      my $sub = eval "sub { $cmd }";
      my $fh = select;
      Coro::async_pool {
         $Coro::current->{desc} = $cmd;
         my $t = Coro::Util::time;
         my @res = eval { &$sub };
         $t = Coro::Util::time - $t;
         print {$fh}
            "\rcommand: $cmd\n",
            "execution time: $t\n",
            "result: ", $@ ? $@ : (join " ", @res) . "\n",
            "> ";
      };

   } else {
      my @res = eval $cmd;
      print $@ ? $@ : (join " ", @res) . "\n";
   }

   local $| = 1;
}

=item session $fh

Run an interactive debugger session on the given filehandle. Each line entered
is simply passed to C<command> (with a few exceptions).

=cut

sub session($) {
   my ($fh) = @_;

   $fh = Coro::Handle::unblock $fh;
   my $old_fh = select $fh;
   my $guard = guard { select $old_fh };

   my $loglevel = $SESLOGLEVEL;
   local $log{$Coro::current} = sub {
      return unless $_[0] <= $loglevel;
      print $fh "\015", (format_msg $_[0], $_[1]), "> ";
   };

   print "coro debug session. use help for more info\n\n";

   while ((print "> "), defined (my $cmd = $fh->readline ("\012"))) {
      if ($cmd =~ /^exit\s*$/) {
         print "bye.\n";
         last;

      } elsif ($cmd =~ /^(?:ll|loglevel)\s*(\d+)?\s*/) {
         $loglevel = defined $1 ? $1 : -1;

      } elsif ($cmd =~ /^(?:w|watch)\s*([0-9.]*)\s+(.*)/) {
         my ($time, $cmd) = ($1*1 || 1, $2);
         my $cancel;

         Coro::async {
            $Coro::current->{desc} = "watch $cmd";
            select $fh;
            until ($cancel) {
               command $cmd;
               Coro::Timer::sleep $time;
            }
         };

         $fh->readable;
         $cancel = 1;

      } elsif ($cmd =~ /^help\s*/) {
         command $cmd;
         print <<EOF;
loglevel <int>		enable logging for messages of level <int> and lower
watch <time> <command>  repeat the given command until STDIN becomes readable
exit			end this session
EOF
      } else {
         command $cmd;
      }

      Coro::cede;
   }
}

=item $server = new_unix_server Coro::Debug $path

Creates a new unix domain socket that listens for connection requests and
runs C<session> on any connection. Normal unix permission checks and umask
applies, so you can protect your socket by puttint it into a protected
directory.

The C<socat> utility is an excellent way to connect to this socket:

   socat readline /path/to/socket

Socat also offers history support:

   socat readline:history=/tmp/hist.corodebug /path/to/socket

The server accepts connections until it is destroyed, so you must keep
the return value around as long as you want the server to stay available.

=cut

sub new_unix_server {
   my ($class, $path) = @_;

   unlink $path;
   my $unlink_guard = guard { unlink $path };

   AnyEvent::Socket::tcp_server "unix/", $path, sub {
      my ($fh) = @_;
      $unlink_guard; # mention it
      Coro::async_pool {
         $Coro::current->desc ("[Coro::Debug session]");
         session $fh;
      };
   } or Carp::croak "Coro::Debug::new_unix_server($path): $!";
}

=item $server = new_tcp_server Coro::Debug $port

Similar to C<new_unix_server>, but binds on a TCP port. I<Note that this is
usually results in a gaping security hole>.

Currently, only a TCPv4 socket is created, in the future, a TCPv6 socket
might also be created.

=cut

sub new_tcp_server {
   my ($class, $port) = @_;

   AnyEvent::Socket::tcp_server undef, $port, sub {
      my ($fh) = @_;
      Coro::async_pool {
         $Coro::current->desc ("[Coro::Debug session]");
         session $fh;
      };
   } or Carp::croak "Coro::Debug::new_tcp_server($port): $!";
}

sub DESTROY {
   my ($self) = @_;

   unlink $self->{path} if exists $self->{path};
   %$self = ();
}

1;

=back

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut


