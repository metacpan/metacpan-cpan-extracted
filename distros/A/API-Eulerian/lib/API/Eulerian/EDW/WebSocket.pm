#/usr/bin/env perl
###############################################################################
#
# @file WebSocket.pm
#
# @brief API::Eulerian::EDW Request module used to read Websocket messages from remote
#        peer
#
# @author Thorillon Xavier:x.thorillon@eulerian.com
#
# @date 26/11/2021
#
# @version 1.0
#
###############################################################################
#
# Setup module name.
#
package API::Eulerian::EDW::WebSocket;
#
# Enforce compilor rules
#
use strict; use warnings;
#
# Import IO::Socket::INET
#
use IO::Socket::INET();
#
# Import Protocol::WebSocket::Client
#
use Protocol::WebSocket::Client;
#
# Import IO::Select
#
use IO::Select;
#
# Import API::Eulerian::EDW::Status
#
use API::Eulerian::EDW::Status;
#
# @brief Allocate and initialize a new API::Eulerian::EDW Websocket.
#
# @param $class - API::Eulerian::EDW::WebSocket class.
# @param $host - Remote host.
# @param $port - Remote port.
#
# @return API::Eulerian::EDW WebSocket instance.
#
sub new
{
  my ( $class, $host, $port ) = @_;
  return bless( {
    _HOOK => undef,
    _SELECT => undef,
    _RFDS => undef,
    _SOCKET => IO::Socket::INET->new(
      PeerAddr => $host, PeerPort => $port,
      Blocking => 1, Proto => 'tcp'
      ),
    }, $class
  );
}
#
# @brief Get Socket.
#
# @param $self - API::Eulerian::EDW::WebSocket instance.
#
# @return Socket.
#
sub _socket
{
  return shift->{ _SOCKET };
}
#
# @brief Get API::Eulerian::EDW Websocket Remote Host.
#
# @param $self - API::Eulerian::EDW::WebSocket instance.
#
# @return Remote Host.
#
sub host
{
  return shift->socket()->peerhost();
}
#
# @brief Get API::Eulerian::EDW Websocket Remote Port.
#
# @param $self - API::Eulerian::EDW::WebSocket instance.
#
# @return Remote Port.
#
sub port
{
  return shift->socket()->peerport();
}
#
# @brief On write Websocket handler.
#
# @param $self - WebSocket.
# @param $data - Data to be writen
#
# @return Writen Size.
#
sub _on_write
{
  my ( $peer, $buf ) = @_;
  $peer->{ _WS }->{ _SOCKET }->syswrite( $buf );
}
#
# @brief On read Websocket handler.
#
# @param $self - Websocket.
#
# @return
#
sub _on_read
{
  my ( $peer, $buf ) = @_;
  my $ws = $peer->{ _WS };
  $ws->{ _HOOK }( $ws, $buf );
}
#
# @brief On error Websocket handler.
#
# @param $self - Websocket.
#
# @return
#
sub _on_error
{
  my ( $self, $error ) = @_;
  print STDERR "Websocket error : $error\n";
}
#
# @brief On connect Websocket handler.
#
# @param $self - Websocket.
#
# @return
#
sub _on_connect
{
}
#
# @brief Join given url in Websocket mode, call hook for each received buffer.
#
# @param $self - API::Eulerian::EDW::WebSocket instance.
# @param $url - Remote url.
# @param $hooks - User specific hook callback.
#
# @return API::Eulerian::EDW::Status instance.
#
sub join
{
  my ( $self, $url, $hook ) = @_;
  my $status = API::Eulerian::EDW::Status->new();
  my $socket = $self->_socket();
  my $bufsize = 4 * 1024 * 1024;
  my $offset = 0;
  my $buf = '';
  my $read;
  my $rfds;
  my $peer;

  # Create a Websocket
  $peer = Protocol::WebSocket::Client->new(
    url => $url,
    max_payload_size => $bufsize
  );

  # Setup Websocket hooks
  $peer->on( write   => \&API::Eulerian::EDW::WebSocket::_on_write );
  $peer->on( read    => \&API::Eulerian::EDW::WebSocket::_on_read );
  $peer->on( error   => \&API::Eulerian::EDW::WebSocket::_on_error );
  $peer->on( connect => \&API::Eulerian::EDW::WebSocket::_on_connect );

  # Save back refs
  $self->{ _HOOK } = $hook;
  $peer->{ _WS } = $self;

  # Connect on remote host
  $peer->connect;

  # If connected
  if( defined( $socket->connected ) ) {
    for(; defined( $socket ); ) {
      $read = $socket->sysread( $buf, $bufsize, $offset );
      if( $read > 0 ) {
        $peer->read( $buf );
      } else {
        close( $socket );
        undef( $socket );
        last;
      }
    }
  }

  # Disconnect from remote host
  $peer->disconnect;

  return $status;
}
#
# End up module properly
#
1;

__END__

=pod

=head1  NAME

API::Eulerian::EDW::WebSocket - API::Eulerian::EDW WebSocket module.

=head1 DESCRIPTION

This module is used to read WebSocket message from remote host.

=head1 METHODS

=head2 new()

I<Create a new instance of API::Eulerian::EDW Websocket>

=head3 input

=over 4

=item * host - Remote host.

=item * port - Remote port.

=back

=head3 output

=over 4

=item * API::Eulerian::EDW::Websocket instance.

=back

=head2 join()

I<Join Websocket, read message and call matching callback hook>

=head3 input

=over 4

=item * url - Remote URL.

=item * hook - User specific hook function used to consume incoming message.

=back

=head3 output

=over 4

=item * API::Eulerian::EDW::Status.

=back

=head1 SEE ALSO

L<IO::Socket::INET>

L<IO::Select>

L<Protocol::WebSocket::Client>

L<API::Eulerian::EDW::Status>

=head1 AUTHOR

Xavier Thorillon <x.thorillon@eulerian.com>

=head1 COPYRIGHT

Copyright (c) 2008 API::Eulerian::EDW Technologies Ltd L<http://www.eulerian.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

=cut
