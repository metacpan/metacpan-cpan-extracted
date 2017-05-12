package Proc::Apult;

use strictures 2;
use Proc::Apult::Client;
use Proc::Apult::Launcher;
use IO::Async::Loop;
use IO::Async::Listener;
use IO::Socket::UNIX;
use Object::Tap;
use curry;
use Moo;

has loop => (is => 'lazy', builder => sub {
  IO::Async::Loop->new
});

has socket_path => (is => 'ro', required => 1);

has listen_socket => (is => 'lazy', builder => sub {
  my ($self) = @_;
  my $path = $self->socket_path;
  unlink $path if -e $path;
  my $socket = IO::Socket::UNIX->new(
    Local => $path,
    Listen => 1
  ) or die "Couldn't create ${\$self->socket_path} - $!\n";
  return $socket;
});

has listener => (is => 'lazy', builder => sub {
  my ($self) = @_;
  IO::Async::Listener->new(
    on_stream => $self->curry::weak::accept_client
  )->$_tap(sub {
    $self->loop->add($_[0]);
    $_[0]->listen(handle => $self->listen_socket);
  })
});

has launcher => (is => 'lazy', builder => sub {
  Proc::Apult::Launcher->new(
    master => $_[0],
  );
}, handles => {
  launcher_start => 'start',
  launcher_stop => 'stop',
});

has current_clients => (is => 'ro', default => sub { {} });

sub broadcast_launcher_status {
  my ($self, $new_status) = @_;
  $_->send_launcher_status($new_status) for values %{$self->current_clients};
}

sub accept_client {
  my ($self, undef, $stream) = @_;
  my $client = Proc::Apult::Client->new(
    master => $self,
    stream => $stream
  );
  $self->loop->add($stream);
  $client->send_launcher_status($self->launcher->current_status);
  $self->current_clients->{$client} = $client;
}

sub remove_client {
  my ($self, $client) = @_;
  delete $self->current_clients->{$client};
}

sub commit_harakiri {
  exit(0);
}

sub run {
  my ($self) = @_;
  $self->listener;
  $self->loop
       ->$_tap(watch_signal => INT => sub {})
       ->$_tap(watch_signal => QUIT => sub {})
       ->run;
}

1;
