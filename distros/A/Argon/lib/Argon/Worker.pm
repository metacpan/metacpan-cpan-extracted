package Argon::Worker;
# ABSTRACT: Argon worker node providing capacity to an Argon::Manager
$Argon::Worker::VERSION = '0.18';

use strict;
use warnings;
use Carp;
use Moose;
use AnyEvent;
use AnyEvent::Util qw(fork_call portable_socketpair fh_nonblocking);
use Argon;
use Argon::Constants qw(:commands :defaults);
use Argon::Log;
use Argon::Marshal;
use Argon::Types;
use Argon::Util qw(K param interval);
require Argon::Channel;
require Argon::Client;
require Argon::Message;

with qw(Argon::Encryption);


has capacity => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);


has mgr_host => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has mgr_port => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);

has timer => (
  is  => 'rw',
  isa => 'Any',
);

has tries => (
  is      => 'rw',
  isa     => 'Int',
  default => 0,
);

has intvl => (
  is       => 'ro',
  isa      => 'CodeRef',
  default  => sub { interval(1) },
  init_arg => undef,
);

has mgr => (
  is  => 'rw',
  isa => 'Argon::Client',
);

has workers => (
  is  => 'rw',
  isa => 'ArrayRef',
  default => sub {[]},
);

has assigned => (
  is  => 'rw',
  isa => 'HashRef',
  default => sub {{}},
);


sub BUILD {
  my ($self, $args) = @_;
  $AnyEvent::Util::MAX_FORKS = $self->capacity;
  $self->add_worker foreach 1 .. $self->capacity;
}


sub start {
  my $self = shift;
  $self->connect;
}


sub connect {
  my $self = shift;
  $self->timer(undef);
  $self->tries($self->tries + 1);

  log_trace 'Connecting to manager (attempt %d)', $self->tries;

  $self->mgr(Argon::Client->new(
    key    => $self->key,
    token  => $self->token,
    host   => $self->mgr_host,
    port   => $self->mgr_port,
    ready  => K('register', $self),
    closed => K('_disconnected', $self),
    notify => K('_queue', $self),
  ));

  $self->intvl->(1); # reset
}

sub _disconnected {
  my $self = shift;
  log_debug 'Manager disconnected' unless $self->timer;
  $self->reconnect;
}

sub reconnect {
  my $self = shift;
  my $intvl = $self->intvl->();
  $self->timer(AnyEvent->timer(after => $intvl, cb => K('connect', $self)));
  log_debug 'Reconection attempt in %0.4fs', $intvl;
}

sub register {
  my $self = shift;
  log_note 'Connected to manager';
  log_trace 'Registering with manager';

  my $msg = Argon::Message->new(
    cmd  => $HIRE,
    info => {capacity => $self->capacity},
  );

  $self->mgr->send($msg);
  $self->mgr->reply_cb($msg, K('_mgr_registered', $self));
}

sub _mgr_registered {
  my ($self, $msg) = @_;
  if ($msg->failed) {
    log_error 'Failed to register with manager: %s', $msg->info;
  }
  else {
    log_info 'Accepting tasks';
    log_note 'Direct code execution is permitted'
      if $Argon::ALLOW_EVAL;
  }
}

sub _queue {
  my ($self, $msg) = @_;
  if (my $worker = shift @{$self->{workers}}) {
    my ($id, $chan) = @$worker;
    $chan->send($msg);
    $self->{assigned}{$id} = $worker;
  } else {
    log_debug 'No available capacity';
    $self->mgr->send($msg->reply(cmd => $DENY, info => "No available capacity. Please try again later."));
  }
}

sub _result {
  my ($self, $id, $reply) = @_;
  push @{$self->{workers}}, delete $self->{assigned}{$id};
  $self->mgr->send($reply);
}

sub _worker_closed {
  my ($self, $id) = @_;
  delete $self->assigned->{$id};
  $self->{workers} = [ grep { $_->[0] ne $id } @{$self->{workers}} ];
  $self->add_worker;
}

sub add_worker {
  my $self = shift;
  my $id = $self->create_token;
  my $on_close = K('_worker_closed', $self, $id);

  my ($left, $right) = portable_socketpair;

  fork_call {
    use Class::Load qw(load_class);
    use Argon::Log;
    use Argon::Marshal;

    close $left;
    $\ = $EOL;

    log_trace 'subprocess: running';

    eval {
      while (defined(my $line = <$right>)) {
        eval {
          chomp $line;
          my $msg = decode_msg($line);

          my $result = eval {
            my ($class, @args) = @{$msg->info};
            load_class($class);
            $class->new(@args)->run;
          };

          my $reply = $@
            ? $msg->error($@)
            : $msg->reply(cmd => $DONE, info => $result);

          syswrite $right, encode_msg($reply);
          syswrite $right, $EOL;
        };

        $@ && log_warn 'subprocess: %s', $@;
      }
    };

    $@ && log_error 'subprocess: %s', $@;
    exit 0;
  };

  close $right;
  fh_nonblocking $left, 1;

  my $channel = Argon::Channel->new(
    fh       => $left,
    on_close => $on_close,
    on_err   => $on_close,
    on_msg   => K('_result', $self, $id),
  );

  push @{$self->{workers}}, [$id, $channel];
  log_trace 'subprocess started';
  return $id;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Worker - Argon worker node providing capacity to an Argon::Manager

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  use Argon::Worker;
  use AnyEvent;

  my $cv = AnyEvent->condvar;

  my $worker = Argon::Worker->new(
    keyfile  => 'path/to/secret',
    capacity => 4,
    mgr_host => 'some.host-addr.com',
    mgr_port => 8000,
  );

  $cv->recv;

=head1 DESCRIPTION

Workers do the actual work of executing the tasks assigned to them by
the L<Argon::Manager>.

For most use cases, this class need not be access directly; instead,
L<bin/ar-worker> provides a command-line interface to control the manager
process.

=head1 ATTRIBUTES

=head2 keyfile

Path to the file containing the encryption pass phrase. Inherited from
L<Argon::Encryption>.

=head2 capacity

The number of tasks which this worker can handle concurrently.

=head2 mgr_hsot

The host name or IP of the manager process.

=head2 mgr_port

The port number on which the manager is listening.

=head1 METHODS

=head2 start

Starts the worker.

=head2 connect

Connects to the manager service. Called by L</start>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
