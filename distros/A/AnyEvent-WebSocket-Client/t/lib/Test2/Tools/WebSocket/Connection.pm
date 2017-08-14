package Test2::Tools::WebSocket::Connection;

use strict;
use warnings;
use Test2::API qw( context );
use AnyEvent::Handle;
use AnyEvent::Socket qw(tcp_server);
use base qw( Exporter );

our @EXPORT_OK = qw( create_connection_pair create_connection_and_handle );

# ABSTRACT: Test AnyEvent::WebSocket::Connection without a server or client
# VERSION

=head1 SYNOPSIS

 use Test2::Tools::WebSocket::Connection qw( create_connection_pair );
 
 my($a, $b) = create_connection_pair;
 
=head1 DESCRIPTION

This module provides a function for building a pair of L<AnyEvent::WebSocket::Connection>
objects that can be used for testing.

=cut

sub _create_handle_pair
{
  my @ports;
  my $cv_port = AnyEvent->condvar;
  my $cv_server_fh = AnyEvent->condvar;
  my $server = tcp_server undef, undef, sub {
    my ($fh, $host, $port) = @_;
    $ports[0] = $port;
    $cv_server_fh->send($fh);
  }, sub {
    my($fh, $host, $port) = @_;
    $ports[1] = $port;
    $cv_port->send($port);
  };
  my $cv_connect = AnyEvent->condvar;
  my $a_handle = AnyEvent::Handle->new(
    connect => ["127.0.0.1", $cv_port->recv],
    on_error => sub { die "connect error: $_[2]" },
    on_connect => sub { $cv_connect->send() }
  );
  $cv_connect->recv;
  my $b_handle = AnyEvent::Handle->new(
     fh => $cv_server_fh->recv  
  );
  
  my $ctx = context();
  $ctx->note("create connection pair " . join(':', @ports));
  $ctx->release;
  
  return ($a_handle, $b_handle);
}

=head1 FUNCTIONS

=head2 create_connection_pair

 my($a,$b) = create_connection_pair;
 my($a,$b) = create_connection_pair(\%a_options, \%b_options);

This function creates a pair of connection object which are connected.  When
you send a message on one end it will be received on the other.  The
optional option hashes are passed into L<AnyEvent::WebSocket::Connection>
so you can use any option that is legal there.

=cut

sub create_connection_pair
{
  my ($a_options_ref, $b_options_ref) = @_;
  $a_options_ref ||= {};
  $b_options_ref ||= {};
  my ($a_handle, $b_handle) = _create_handle_pair();
  require AnyEvent::WebSocket::Connection;
  return (
    AnyEvent::WebSocket::Connection->new(%$a_options_ref, handle => $a_handle),
    AnyEvent::WebSocket::Connection->new(%$b_options_ref, handle => $b_handle),
  );
}

=head2 create_connection_and_handle

 my($connection, $handle) = create_connection_and_handle;
 my($connection, $handle) = create_connection_and_handle(\%connection_options);

This is the same as create_connection_pair, except a L<AnyEvent::Handle> object
is returned for one end.  This can be useful for some lower level testing.

=cut


sub create_connection_and_handle
{
  my ($a_options_ref) = @_;
  my ($a_handle, $b_handle) = _create_handle_pair();
  require AnyEvent::WebSocket::Connection;
  return (
    AnyEvent::WebSocket::Connection->new(%$a_options_ref, handle => $a_handle),
    $b_handle
  );
}

1;


=head1 SEEL ALSO

=over 4

=item L<AnyEvent::WebSocket::Client>

=item L<AnyEvent::WebSocket::Server>

=item L<Test::Mojo>

Also provides methods for testing websockets.

=back

=cut
