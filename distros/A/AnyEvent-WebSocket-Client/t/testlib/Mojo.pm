package testlib::Mojo;

use strict;
use warnings;
use Mojo::Server::Daemon;
use Test::More;

sub start_mojo
{
  my ($class, %args) = @_;
  my $app = $args{app};
  my $scheme = $args{ssl} ? "https" : "http";
  my $server = Mojo::Server::Daemon->new;
  my $port = generate_port();
  note "port = $port";
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
