package testlib::Connection;

use strict;
use warnings;
use AnyEvent::WebSocket::Connection;
use AnyEvent::Handle;
use AnyEvent::Socket qw(tcp_server);

sub create_handle_pair
{
  my $cv_port = AnyEvent->condvar;
  my $cv_server_fh = AnyEvent->condvar;
  my $server = tcp_server undef, undef, sub {
    my ($fh) = @_;
    $cv_server_fh->send($fh);
  }, sub {
    my($fh, $host, $port) = @_;
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
  return ($a_handle, $b_handle);
}

sub create_connection_pair
{
  my ($class, $a_options_ref, $b_options_ref) = @_;
  $a_options_ref ||= {};
  $b_options_ref ||= {};
  my ($a_handle, $b_handle) = $class->create_handle_pair();
  return (
    AnyEvent::WebSocket::Connection->new(%$a_options_ref, handle => $a_handle),
    AnyEvent::WebSocket::Connection->new(%$b_options_ref, handle => $b_handle),
  );
}

sub create_connection_and_handle
{
  my ($class, $a_options_ref) = @_;
  my ($a_handle, $b_handle) = $class->create_handle_pair();
  return (
    AnyEvent::WebSocket::Connection->new(%$a_options_ref, handle => $a_handle),
    $b_handle
  );
}

1;
