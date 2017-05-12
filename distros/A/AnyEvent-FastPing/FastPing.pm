=head1 NAME

AnyEvent::FastPing - quickly ping a large number of hosts

=head1 SYNOPSIS

 use AnyEvent::FastPing;

=head1 DESCRIPTION

This module was written for a single purpose only: sending ICMP ECHO
REQUEST packets as quickly as possible to a large number of hosts
(thousands to millions).

It employs a separate thread and is fully event-driven (using AnyEvent),
so you have to run an event model supported by AnyEvent to use this
module.

=head1 FUNCTIONS

=over 4

=cut

package AnyEvent::FastPing;

use common::sense;

use AnyEvent;

BEGIN {
   our $VERSION = 2.1;
   our @ISA = qw(Exporter);

   require Exporter;
   #Exporter::export_ok_tags (keys %EXPORT_TAGS);

   require XSLoader;
   XSLoader::load (__PACKAGE__, $VERSION);
}

our ($THR_RES_FD, $ICMP4_FD, $ICMP6_FD);

our $THR_RES_FH;

our $ICMP4_FH;
our $ICMP6_FH;

our @IDLE_CB;

=item AnyEvent::FastPing::ipv4_supported

Returns true iff IPv4 is supported in this module and on this system.

=item AnyEvent::FastPing::ipv6_supported

Returns true iff IPv6 is supported in this module and on this system.

=item AnyEvent::FastPing::icmp4_pktsize

Returns the number of octets per IPv4 ping packet (the whole IP packet
including headers, excluding lower-level headers or trailers such as
Ethernet).

Can be used to calculate e.g. octets/s from rate ...

   my $octets_per_second = $packets_per_second * AnyEvent::FastPing::icmp4_pktsize;

... or convert kilobit/second to packet rate ...

   my $packets_per_second = $kilobit_per_second
                            * (1000 / 8 / AnyEvent::FastPing::icmp4_pktsize);

etc.

=item AnyEvent::FastPing::icmp6_pktsize

Like AnyEvent::FastPing::icmp4_pktsize, but for IPv6.

=back

=head1 THE AnyEvent::FastPing CLASS

The AnyEvent::FastPing class represents a single "pinger". A "pinger"
comes with its own thread to send packets in the background, a rate-limit
machinery and separate idle/receive callbacks.

The recommended workflow (there are others) is this: 1. create a new
AnyEvent::FastPing object 2. configure the address lists and ranges to
ping, also configure an idle callback and optionally a receive callback
3. C<start> the pinger.

When the pinger has finished pinging all the configured addresses it will
call the idle callback.

The pinging process works like this: every range has a minimum interval
between sends, which is used to limit the rate at which hosts in that
range are being pinged. Distinct ranges are independent of each other,
which is why there is a per-pinger "global" minimum interval as well.

The pinger sends pings as fats as possible, while both obeying the pinger
rate limit as well as range limits.

When a range is exhausted, it is removed. When all ranges are exhausted,
the pinger waits another C<max_rtt> seconds and then exits, causing the
idle callback to trigger.

Performance: On my 2 GHz Opteron system with a pretty average nvidia
gigabit network card I can ping around 60k to 200k addresses per second,
depending on routing decisions.

Example: ping 10.0.0.1-10.0.0.15 with at most 100 packets/s, and
11.0.0.1-11.0.255.255 with at most 1000 packets/s. Also ping the IPv6
loopback address 5 times as fast as possible. Do not, however, exceed 1000
packets/s overall. Also dump each received reply.

   use AnyEvent::Socket;
   use AnyEvent::FastPing;

   my $done = AnyEvent->condvar;

   my $pinger = new AnyEvent::FastPing;

   $pinger->interval (1/1000);
   $pinger->max_rtt (0.1); # reasonably fast/reliable network

   $pinger->add_range (v10.0.0.1, v10.0.0.15, 1/100);
   $pinger->add_range (v11.0.0.1, v11.0.255.255, 1/1000);
   $pinger->add_hosts ([ (v0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1) x 5 ]);

   $pinger->on_recv (sub {
      for (@{ $_[0] }) {
         printf "%s %g\n", (AnyEvent::Socket::format_address $_->[0]), $_->[1];
      }
   });

   $pinger->on_idle (sub {
      print "done\n";
      undef $pinger;
   });

   $pinger->start;
   $done->wait;

=head2 METHODS

=over 4

=item $pinger = new AnyEvent::FastPing

Creates a new pinger - right now there can be at most C<65536> pingers in
a process, although that limit might change to something drastically lower
- you should be stingy with your pinger objects.

=cut

sub new {
   _boot;

   our $ICMP4_W = $ICMP4_FD >= 0 && (open $ICMP4_FH, "<&=$ICMP4_FD") && AE::io $ICMP4_FH, 0, \&_recv_icmp4;
   our $ICMP6_W = $ICMP6_FD >= 0 && (open $ICMP6_FH, "<&=$ICMP6_FD") && AE::io $ICMP6_FH, 0, \&_recv_icmp6;

   open $THR_RES_FH, "<&=$THR_RES_FD" or die "AnyEvent::FastPing: FATAL: cannot fdopen thread result fd";

   our $THR_RES_W = AE::io $THR_RES_FH, 0, sub {
      sysread $THR_RES_FH, my $buf, 8;

      for my $id (unpack "S*", $buf) {
         _stop_id $id;
         ($IDLE_CB[$id] || sub { })->();
      }
   };

   *new = sub {
      _new shift, (rand 65536), (rand 65536), (rand 65536)
   };

   goto &new;
}

sub DESTROY {
   undef $IDLE_CB[ &id ];
   &_free;
}

=item $pinger->on_recv ($callback->([[$host, $rtt], ...]))

Registers a callback to be called for ping replies. If no callback has
been registered than ping replies will be ignored, otherwise this module
calculates the round trip time, in seconds, for each reply and calls this
callback.

The callback receives a single argument, which is an array reference
with an entry for each reply packet (the replies will be batched for
efficiency). Each member in the array reference is again an array
reference with exactly two members: the binary host address (4 octets for
IPv4, 16 for IPv6) and the approximate round trip time, in seconds.

The replies will be passed to the callback as soon as they arrive, and
this callback can be called many times with batches of replies.

The receive callback will be called whenever a suitable reply arrives,
whether generated by this pinger or not, whether this pinger is started
or not. The packets will have a unique 64 bit ID to distinguish them from
other pinger objects and other generators, but this doesn't help against
malicious replies.

Note that very high packet rates can overwhelm your process, causing
replies to be dropped (configure your kernel with long receive queues for
raw sockets if this is a problem).

Example: register a callback which simply dumps the received data.

   use AnyEvent::Socket;

   $pinger->on_recv (sub {
      for (@{ $_[0] }) {
         printf "%s %g\n", (AnyEvent::Socket::format_address $_->[0]), $_->[1];
      }
   });

Example: a single ping reply with payload of 1 from C<::1> gets passed
like this:

   [
      [ "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\1", 0.000280141830444336 ]
   ]

Example: ping replies for C<127.0.0.1> and C<127.0.0.2>:

   [
      [ "\177\0\0\1", 0.00015711784362793 ],
      [ "\177\0\0\2", 0.00090184211731 ]
   ]

=item $pinger->on_idle ($callback->())

Registers a callback to be called when the pinger becomes I<idle>, that
is, it has been started, has exhausted all ping ranges and waited for
the C<max_rtt> time. An idle pinger is also stopped, so the callback can
instantly add new ranges, if it so desires.

=cut

sub on_idle {
   $IDLE_CB[ &id ] = $_[1];
}

=item $pinger->interval ($seconds)

Configures the minimum interval between packet sends for this pinger - the
pinger will not send packets faster than this rate (or actually 1 / rate),
even if individual ranges have a lower interval.

A value of C<0> selects the fastest possible speed (currently no faster
than 1_000_000 packets/s).

=item $pinger->max_rtt ($seconds)

If your idle callback were called instantly after all ranges were
exhausted and you destroyed the object inside (which is common), then
there would be no chance to receive some replies, as there would be no
time of the packet to travel over the network.

This can be fixed by starting a timer in the idle callback, or more simply
by selecting a suitable C<max_rtt> value, which should be the maximum time
you allow a ping packet to travel to its destination and back.

The pinger thread automatically waits for this amount of time before becoming idle.

The default is currently C<0.5> seconds, which is usually plenty.

=item $pinger->add_range ($lo, $hi[, $interval])

Ping the IPv4 (or IPv6, but see below) address range, starting at binary
address C<$lo> and ending at C<$hi> (both C<$lo> and C<$hi> will be
pinged), generating no more than one ping per C<$interval> seconds (or as
fast as possible if omitted).

You can convert IP addresses from text to binary form by
using C<AnyEvent::Util::parse_address>, C<Socket::inet_aton>,
C<Socket6::inet_pton> or any other method that you like :)

The algorithm to select the next address is O(log n) on the number of
ranges, so even a large number of ranges (many thousands) is manageable.

No storage is allocated per address.

Note that, while IPv6 addresses are currently supported, the usefulness of
this option is extremely limited and might be gone in future versions - if
you want to ping a number of IPv6 hosts, better specify them individually
using the C<add_hosts> method.

=item $pinger->add_hosts ([$host...], $interval, $interleave)

Similar to C<add_range>, but uses a list of single addresses instead. The
list is specified as an array reference as first argument. Each entry in
the array should be a binary host address, either IPv4 or IPv6. If all
addresses are IPv4 addresses, then a compact IPv4-only format will be used
to store the list internally.

Minimum C<$interval> is the same as for C<add_range> and can be left out.

C<$interlave> specifies an increment between addresses: often address
lists are generated in a way that results in clustering - first all
addresses from one subnet, then from the next, and so on. To avoid this,
you can specify an interleave factor. If it is C<1> (the default), then
every address is pinged in the order specified. If it is C<2>, then only
every second address will be pinged in the first round, followed by a
second round with the others. Higher factors will create C<$interleave>
runs of addresses spaced C<$interleave> indices in the list.

The special value C<0> selects a (hopefully) suitable interleave factor
automatically - currently C<256> for lists with less than 65536 addresses,
and the square root of the list length otherwise.

=item $pinger->start

Start the pinger, unless it is running already. While a pinger is running
you must not modify the pinger. If you want to change a parameter, you
have to C<stop> the pinger first.

The pinger will automatically stop when destroyed.

=item $pinger->stop

Stop the pinger, if it is running. A pinger can be stopped at any time,
after which it's current state is preserved - starting it again will
continue where it left off.

=cut

1;

=back

=head1 AUTHOR

   Marc Lehmann <schmorp@schmorp.de>
   http://home.schmorp.de/

=head1 LICENSE

   This software is distributed under the GENERAL PUBLIC LICENSE, version 2
   or any later version or, at your option, the Artistic License.

=cut

