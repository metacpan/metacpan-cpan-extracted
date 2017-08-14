package Test2::Tools::WebSocket::Mojo;

use strict;
use warnings;
use base qw( Exporter );
use Mojo::Server::Daemon;
use Test2::API qw( context );

our @EXPORT_OK = qw( start_mojo );

sub start_mojo
{
  my (%args) = @_;
  my $app = $args{app};
  my $scheme = $args{ssl} ? "https" : "http";
  my $server = Mojo::Server::Daemon->new;
  my $port = generate_port();
  my $ctx = context();
  $ctx->note("port = $port");
  $ctx->release;
  $server->app($app);
  $server->listen(["$scheme://127.0.0.1:$port"]);
  $server->start;
  return ($server, $port);
}

sub generate_port
{
  IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1')->sockport
}

1;
