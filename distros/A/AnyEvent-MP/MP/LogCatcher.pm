=head1 NAME

AnyEvent::MP::LogCatcher - catch all logs from all nodes

=head1 SYNOPSIS

   use AnyEvent::MP::LogCatcher;

=head1 DESCRIPTION

This relatively simple module attaches itself to the
C<$AnyEvent::Log::COLLECT> context on every node and sends all log
messages to the node showing interest via the C<catch> function.

No attempt to buffer log messages on connection loss, or to retransmit
lost messages, is done.

=head1 GLOBALS AND FUNCTIONS

=over 4

=cut

package AnyEvent::MP::LogCatcher;

use common::sense;
use Carp ();
use POSIX ();

use AnyEvent ();
use AnyEvent::Log ();
use AnyEvent::Util ();

use AnyEvent::MP;
use AnyEvent::MP::Kernel;

use base "Exporter";

AE::log 7 => "starting log catcher service.";

our $LOGLEVEL;
our $MON;
our $PROPAGATE = 1; # set to one when messages ought to be send to remote nodes
our %LPORT; # local logging ports

# other nodes connect via this
sub connect {
   my ($version, $rport, $loglevel) = @_;

   # context to catch log messages
   my $ctx = new AnyEvent::Log::Ctx
      title  => "AnyEvent::MP::LogCatcher",
      level  => $loglevel,
      log_cb => sub {
         snd $rport, @{ $_[0] }
            if $PROPAGATE;
      },
      fmt_cb => sub {
         [$_[0], $_[1]->title, $_[2], $_[3]]
      },
   ;

   $AnyEvent::Log::COLLECT->attach ($ctx);

   # monitor them, silently die if they die
   mon $rport, sub {
      $AnyEvent::Log::COLLECT->detach ($ctx);
   };

   AE::log 8 => "starting to propagate log messages to $rport";
}

sub mon_node {
   my ($node) = @_;

   # don't log messages from ourselves
   return if $node eq $NODE;

   $LPORT{$node} ||= do {
      my $lport = port {
         my ($time, $ctx, $level, $msg) = @_;

         $level = 2 if $level < 2; # do not exit just because others do so

         my $diff = AE::now - $time;
         $diff = (abs $diff) < 1e-3 ? "" : sprintf "%+.3fs", $diff;

         local $PROPAGATE; # do not propagate to other nodes
         (AnyEvent::Log::ctx $ctx)->log ($level, "[$node$diff] $msg");
      };

      mon $lport, sub {
         delete $LPORT{$node}
            or return; # do not monitor if node is not there
         AE::log error => "@_"
            if @_; # log error if there really was one
         mon_node ($node); # try to reocnnect
      };

      # establish connection
      AnyEvent::MP::Kernel::snd_to_func $node, "AnyEvent::MP::LogCatcher::connect", 0, $lport, $LOGLEVEL;

      mon $node, $lport;

      $lport
   }
}

=item AnyEvent::MP::LogCatcher::catch [$level]

Starts catching all log messages from all nodes with level C<$level> or
lower. If the C<$level> is C<undef>, then stop catching all messages
again.

Example: start a node that catches all messages (you might have to specify
a suitable profile name).

   AE_VERBOSE=9 aemp run profilename services '[["AnyEvent::MP::LogCatcher::catch",9]]'

=cut

sub catch {
   $LOGLEVEL = $_[0];
   kil $_ for values %LPORT;
   %LPORT = ();

   return unless defined $LOGLEVEL;

   $MON = db_mon "'l" => sub {
      my ($family, $add, $chg, $del) = @_;

      kil delete $LPORT{$_}
         for @$del;

      mon_node $_
         for @$add;
   };

   ()
}

=back

=head1 LOGGING

AnyEvent::MP::LogCatcher logs messages from remote nodes. It logs them
into the original logging context and prepends the origin node name
and, if the time difference is larger than 1e-4 seconds, also the time
difference between local time and origin time.

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

