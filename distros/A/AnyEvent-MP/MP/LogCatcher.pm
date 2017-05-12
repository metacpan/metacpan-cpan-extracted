=head1 NAME

AnyEvent::MP::LogCatcher - catch all logs from all nodes

=head1 SYNOPSIS

   use AnyEvent::MP::LogCatcher;

=head1 DESCRIPTION

This relatively simple module overrides C<$AnyEvent::MP::Kernel::WARN> on
every node and sends all log messages to the node running this service.

No attempt to buffer log messages on connection loss, or retransmit lost
messages, is done.

=head1 GLOBALS AND FUNCTIONS

=over 4

=cut

package AnyEvent::MP::LogCatcher;

use common::sense;
use Carp ();
use POSIX ();

use AnyEvent ();
use AnyEvent::Util ();

use AnyEvent::MP;
use AnyEvent::MP::Kernel;

use base "Exporter";

$AnyEvent::MP::Kernel::WARN->(7, "starting log catcher service.");

our $LOGLEVEL;
our %lport; # local logging ports

# other nodes connect via this
sub connect {
   my ($version, $rport, $loglevel) = @_;

   my $cb = sub {
      snd $rport, @_
         if $_[0] <= $loglevel;
   };

   push @AnyEvent::MP::Kernel::WARN, $cb;

   # monitor them, silently die
   mon $rport, sub {
      @AnyEvent::MP::Kernel::WARN = grep $_ != $cb, @AnyEvent::MP::Kernel::WARN;
   };
}

sub mon_node {
   my ($node, $is_up) = @_;

   return unless $is_up;

   my $lport = $lport{$node} = port {
      my ($level, $msg) = @_;

      $msg =~ s/\n$//;

      printf STDERR "%s [%s] <%d> %s\n",
             (POSIX::strftime "%Y-%m-%d %H:%M:%S", localtime time),
             $node,
             $level,
             $msg;
   };

   # establish connection
   AnyEvent::MP::Kernel::snd_to_func $node, "AnyEvent::MP::LogCatcher::connect", 0, $lport, $LOGLEVEL;

   mon $node, $lport;
}

=item AnyEvent::MP::LogCatcher::catch [$level]

Starts catching all log messages from all nodes with level C<$level> or
lower. If the C<$level> is C<undef>, then stop catching all messages
again.

Example: start a node that catches all messages (you might have to specify
a suitable profile name).

   aemp run profilename services '[["AnyEvent::MP::LogCatcher::catch",9]]'

=cut

sub catch {
   $LOGLEVEL = $_[0];
   kil $_, "restart" for values %lport;
   %lport = ();

   return unless defined $LOGLEVEL;

   mon_node $_, 1
      for up_nodes;

   mon_nodes \&mon_node;
   ()
}

=back

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

