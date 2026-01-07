#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

use v5.36;

use Future::AsyncAwait;
use Object::Pad 0.800;

package Conduit 0.02;
class Conduit
   :strict(params);

=head1 NAME

C<Conduit> - serve HTTP with L<Future::IO>

=head1 SYNOPSIS

=for highlighter language=perl

   use Conduit;
   use Future::AsyncAwait;

   my $server = Conduit->new(
      port     => 8080,
      psgi_app => sub ( $env ) {
         return [
            200,
            [ "Content-Type" => "text/plain" ],
            [ "Hello, world!" ]
         ];
      },
   );

   await $server->run;

=head1 DESCRIPTION

This module allows a program to respond asynchronously to HTTP requests as
part of a program based on L<Future::IO>. It currently only supports a
PSGI-based application, but the intention is to allow PAGI and possibly other
interface shapes in a later version.

This is currently B<experimental>, serving also as a testbed for how to design
larger systems using C<Future::IO>, and hopefully soon as a way to test out
the PAGI design.

This module reports basic metrics about received requests and sent responses
via L<Metrics::Any>, as described by L<Conduit::Metrics>.

=cut

use Carp;

use Future::IO 0.17;
use Future::Selector;
use IO::Socket::IP;

use Conduit::Client;

=head1 PARAMETERS

=head2 port

   port => $int

TCP port number to listen on for HTTP requests.

Either this or the C<listensock> parameter must be provided; though the latter
is intended for internal and unit-test purposes and will not be otherwise
documented.

=cut

field $listensock :param = undef;
ADJUST :params (
   :$port = undef,
) {
   defined( $port ) or defined( $listensock ) or
      croak "Require either 'port' or 'listensock'";

   $listensock //= IO::Socket::IP->new(
      LocalPort => $port,
      Listen    => 5,
      ReuseAddr => 1,
   );
}

method port () { return $listensock->sockport; }

field $selector = Future::Selector->new;

async method listen ()
{
   while( my $clientsock = await Future::IO->accept( $listensock ) ) {
      my $client = Conduit::Client->new(
         server => $self,
         socket => $clientsock,
      );

      $selector->add(
         data => $client,
         f    => $client->run,
      );
   }
}

=head2 psgi_app

   psgi_app => $app

A code reference to the L<PSGI> application used for handling requests.

Currently this is mandatory, but the intention is soon to allow other forms of
responders, such as L<PAGI> as alternatives.

=cut

field $psgi_app :param;

async method respond ( $env )
{
   return $psgi_app->( $env );
}

=head1 METHODS

=cut

=head2 run

   $run_f = $conduit->run;

Starts operation of the server, allowing it to accept new connections, serve
requests, and run the application.

Returns a L<Future> instance that in normal circumstances should never
complete; it will remain pending indefinitely. The toplevel program can either
C<await> this if it has nothing else to do, or add that to a collection such
as with L<Future::Selector>.

=cut

async method run ()
{
   $selector->add( data => "accept", f => $self->listen );
   await $selector->run;
}

=head1 TODO

Honestly, quite a lot. Almost everything in fact. ;)

=over 4

=item *

L<PAGI> support; likely in preference to any more PSGI.

=item *

Maybe support streaming PSGI responses, though it would still be preferrable
to do this with PAGI first.

=item *

Investigate split IPv4+IPv6 serving, whether it needs two socket or one will
suffice. This may be OS-dependent.

=item *

HTTPS, perhaps via L<IO::Socket::SSL> or maybe something newer?

=item *

Look into what's required to support some sort of websocket thing in addition
to plain HTTP.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
