=head1 NAME

Coro::LWP - make LWP non-blocking - as much as possible

=head1 SYNOPSIS

 use Coro::LWP; # afterwards LWP should not block

=head1 ALTERNATIVES

Over the years, a number of less-invasive alternatives have popped up,
which you might find more acceptable than this rather invasive and fragile
module. All of them only support HTTP (and sometimes HTTPS).

=over 4

=item L<AnyEvent::HTTP>

Works fine without Coro. Requires using a very different API than
LWP. Probably the best choice I<iff> you can do with a completely
different event-based API.

=item L<LWP::Protocol::AnyEvent::http>

Makes LWP use L<AnyEvent::HTTP>. Does not make LWP event-based, but allows
Coro threads to schedule unimpeded through its AnyEvent integration.

Let's you use the LWP API normally.

=item L<LWP::Protocol::Coro::http>

Basically the same as above, distinction unclear. :)

=item L<AnyEvent::HTTP::LWP::UserAgent>

A different user agent implementation, not completely transparent to
users, requires Coro.

=back

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module tries to make L<LWP|LWP> non-blocking with respect to other
coroutines as much as possible, and with whatever means it takes.

LWP really tries very hard to be blocking (and relies on a lot of
undocumented functionality in IO::Socket), so this module had to be very
invasive and must be loaded very early to take the proper effect.

Note that the module L<AnyEvent::HTTP> might offer an alternative to the
full L<LWP> that is designed to be non-blocking.

Here is what it currently does (future versions of LWP might require
different tricks):

=over 4

=item It loads Coro::Select, overwriting the perl C<select> builtin I<globally>.

This is necessary because LWP calls select quite often for timeouts and
who-knows-what.

Impact: everybody else uses this (slower) version of select, too. It should be quite
compatible to perls builtin select, though.

=item It overwrites Socket::inet_aton with Coro::Util::inet_aton.

This is necessary because LWP might (and does) try to resolve hostnames
this way.

Impact: some code might not expect coroutine semantics, for example, when
you fork you might prefer the blocking variant because other coroutines
shouldn't actually run.

=item It replaces the base class of Net::HTTP, Net::FTP, Net::NNTP.

This is necessary because LWP does not always use select to see whether
a filehandle can be read/written without blocking, so the base class
C<IO::Socket::INET> needs to be replaced by C<Coro::Socket>.

Impact: Coro::Socket is not at all compatible to IO::Socket::INET. While
it duplicates some undocumented functionality required by LWP, it does not
have all the methods of IO::Socket::INET and might act quite differently
in practise. Also, protocols other than the above mentioned will still block,
at least some of the time.

=back

All this likely makes other libraries than just LWP not block, but thats
just a side effect you cannot rely on.

Increases parallelism is not supported by all libraries, some might cache
data globally.

=cut

package Coro::LWP;

use common::sense;

BEGIN {
   # suppress warnings
   local $^W = 0;
   require Net::Config;
}

# do it as early as possible
use Coro::Select;

# import these so they can grab Socket::inet_aton
use AnyEvent::Util ();
use AnyEvent::DNS ();

use Coro::Util ();
use Coro::Socket ();
use Coro::AnyEvent ();

use Socket ();

use IO::Socket::INET ();

use Net::HTTP ();
use Net::FTP ();
use Net::NNTP ();

our $VERSION = 6.511;

*Socket::inet_aton = \&Coro::Util::inet_aton;

for (@Net::HTTP::ISA, @Net::FTP::ISA, @Net::NTTP::ISA) {
   $_ = Coro::LWP::Socket:: if $_ eq IO::Socket::INET::;
}

package Coro::LWP::Socket;

no warnings;

use base Coro::Socket::;

sub new {
   my $self = shift;

   $self->SUPER::new (@_, partial => 1)
}

1;

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut


