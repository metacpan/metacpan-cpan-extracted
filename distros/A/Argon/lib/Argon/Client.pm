package Argon::Client;
# ABSTRACT: Client-side connection class for Argon systems
$Argon::Client::VERSION = '0.18';

use strict;
use warnings;
use Carp;
use Moose;
use AnyEvent;
use AnyEvent::Socket qw(tcp_connect);
use Data::Dump::Streamer;
use Argon;
use Argon::Async;
use Argon::Constants qw(:commands :priorities);
use Argon::SecureChannel;
use Argon::Log;
use Argon::Message;
use Argon::Types;
use Argon::Util qw(K param interval);

with qw(Argon::Encryption);


has host => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has port => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);


has retry => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has opened => (
  is      => 'rw',
  isa     => 'Ar::Callback',
  default => sub { sub {} },
);


has ready => (
  is      => 'rw',
  isa     => 'Ar::Callback',
  default => sub { sub {} },
);


has failed => (
  is      => 'rw',
  isa     => 'Ar::Callback',
  default => sub { sub {} },
);


has closed => (
  is      => 'rw',
  isa     => 'Ar::Callback',
  default => sub { sub {} },
);


has notify => (
  is      => 'rw',
  isa     => 'Ar::Callback',
  default => sub { sub {} },
);

has remote => (
  is  => 'rw',
  isa => 'Maybe[Str]',
);

has msg => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {{}},
  traits  => ['Hash'],
  handles => {
    has_msg => 'exists',
    get_msg => 'get',
    add_msg => 'set',
    del_msg => 'delete',
    msg_ids => 'keys',
    msgs    => 'values',
  },
);

has channel => (
  is      => 'rw',
  isa     => 'Maybe[Argon::SecureChannel]',
  handles => [qw(send)],
);

has addr => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_addr',
);

sub _build_addr {
  my $self = shift;
  join ':', $self->host, $self->port;
}


around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  my %args  = @_;

  if (exists $args{channel}) {
    # Match encryption settings
    $args{$_} = $args{channel}{$_}
      foreach grep { exists $args{channel}{$_} }
        qw(key keyfile cipher token);
  }

  $class->$orig(%args);
};

sub BUILD {
  my ($self, $args) = @_;

  if ($self->channel) {
    # Set callbacks
    $self->channel->on_msg(K('_notify', $self));
    $self->channel->on_err(K('_error', $self));
    $self->channel->on_close(K('_close', $self));

    if ($self->channel->is_ready) {
      $self->opened->();
      $self->ready->();
    } else {
      $self->channel->on_ready(K('_ready', $self));
      $self->opened->();
    }
  }
  else {
    $self->connect;
  }
}

sub connect {
  my $self = shift;
  log_debug 'Connecting to %s', $self->addr;
  tcp_connect $self->host, $self->port, K('_connected', $self);
}

sub _connected {
  my ($self, $fh) = @_;

  if ($fh) {
    log_debug '[%s] Connection established', $self->addr;

    $self->channel(Argon::SecureChannel->new(
      fh       => $fh,
      key      => $self->key,
      token    => $self->token,
      remote   => $self->remote,
      on_msg   => K('_notify', $self),
      on_ready => K('_ready',  $self),
      on_err   => K('_error',  $self),
      on_close => K('_close',  $self),
    ));

    $self->opened->();
  }
  else {
    log_debug '[%s] Connection attempt failed: %s', $self->addr, $!;
    $self->cleanup;
    $self->failed->($!);
  }
}

sub reply_cb {
  my ($self, $msg, $cb, $retry) = @_;
  $self->add_msg($msg->id, {
    orig  => $msg,
    cb    => $cb,
    intvl => interval(1),
    retry => $retry,
  });
}


sub ping {
  my ($self, $cb) = @_;
  my $msg = Argon::Message->new(cmd => $PING);
  $self->send($msg);
  $self->reply_cb($msg, $cb);
}


sub queue {
  my ($self, $class, $args, $cb) = @_;
  my $msg = Argon::Message->new(cmd => $QUEUE, info => [$class, @$args]);
  $self->send($msg);
  $self->reply_cb($msg, $cb, $self->retry);
}


sub process {
  Argon::ASSERT_EVAL_ALLOWED;
  my ($self, $code_ref, $args, $cb) = @_;
  $args ||= [];

  my $code = Dump($code_ref)
    ->Purity(1)
    ->Declare(1)
    ->Out;

  $self->queue('Argon::Task', [$code, $args], $cb);
}


sub async ($\[&$]\@) {
  my ($self, $code_ref, $args) = @_;
  my $cv = AnyEvent->condvar;
  $self->process($code_ref, $args, $cv);
  tie my $async, 'Argon::Async', $cv;
  return $async;
}

sub cleanup {
  my $self = shift;
  $self->closed->();
  $self->channel(undef);

  my $error = 'Remote host was disconnected before task completed';

  foreach my $id ($self->msg_ids) {
    my $info = $self->get_msg($id);
    my $cb   = $info->{cb} or next;
    my $msg  = $info->{orig};
    $cb->($msg->error($error));
  }
}

sub _ready { shift->ready->() }

sub _error {
  my ($self, $error) = @_;
  log_error '[%s] %s', $self->addr, $error;
  $self->cleanup;
}

sub _close {
  my ($self) = @_;
  log_debug '[%s] Remote host disconnected', $self->addr;
  $self->cleanup;
}

sub _notify {
  my ($self, $msg) = @_;

  if ($self->has_msg($msg->id)) {
    my $info = $self->del_msg($msg->id);

    if ($msg->denied && $info->{retry}) {
      my $copy  = $info->{orig}->copy;
      my $intvl = $info->{intvl}->();
      log_debug 'Retrying message in %0.2fs: %s', $intvl, $info->{orig}->explain;

      $self->add_msg($copy->id, {
        orig  => $copy,
        cb    => $info->{cb},
        intvl => $info->{intvl},
        retry => 1,
        timer => AnyEvent->timer(after => $intvl, cb => K('send', $self, $copy)),
      });

      return;
    }

    if ($info->{cb}) {
      $info->{cb}->($msg);
    }
    else {
      $self->notify->($msg);
    }
  }
  else {
    $self->notify->($msg);
  }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Client - Client-side connection class for Argon systems

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  use Argon::Client;
  use AnyEvent;

  my $cv = AnyEvent->condvar;

  my $ar = Argon::Client->new(
    host   => 'some.host.net',
    port   => 1234,
    retry  => 1,
    opened => $cv,
    ready  => sub{},
    failed => sub{},
    closed => sub{},
    notify => sub{},
  );

  $cv->recv;

  while (my $task = get_next_task) {
    $ar->process($task->class, $task->args, \&task_complete);
  }

  my $result = $ar->async(sub{ ... });
  if ($result eq 'fnord') {
    ...
  }

=head1 DESCRIPTION

Provides the client connection to an L<Argon> network.

=head1 ATTRIBUTES

=head2 host

The hostname of the L<Argon::Manager> serving as the entry point for the
Argon network.

=head2 port

The port number for the L<Argon::Manager>.

=head2 retry

By default, when the network is at capacity, new tasks may be rejected, causing
L<Argon::Message/result> to croak. If C<retry> is set, the C<Argon::Client>
will instead retry the task on a logarithmic backoff timer until the task is
accepted by the manager.

=head2 opened

A code ref that is triggered when the connection is initially opened.

=head2 ready

A code ref that is triggered when the connection has been opened and the
client is ready to begin sending tasks.

=head2 failed

A code ref that is triggered when the connection fails. The value of C<$!> is
passed as an argument.

=head2 closed

A code ref that is triggered when the connection to the remote host is
closed.

=head2 notify

When tasks are created without a callback (see L<Argon::Client/process>),
the C<notify> callback is used in its place. The L<Argon::Message> reply
is passed as an argument.

=head1 METHODS

=head2 ping

Pings the L<Argon::Manager> and calls the supplied callback with the manager's
reply.

  $ar->ping(sub{ my $reply = shift; ... });

=head2 queue

Queues a task with the Ar manager. Accepts the name of a class accessible to
the workers defining a C<new> and C<run> method, an array of arguments to be
passed to C<new>, and an optional code ref to be called when the task is
complete. If not supplied, the L<Argon::Client/notify> method will be called in
its place.

  $ar->queue('Task::Class', $args_list, sub{
    my $reply = shift;
    ...
  });

=head2 process

If the Ar workers were started with C<--allow-eval> and if the client process
itself has C<$Argon::ALLOW_EVAL> set to a true value, a code ref may be passed
in place of a task class. The code ref will be serialized using
L<Data::Dump::Streamer> and has limited support for closures.

  $ar->process(sub{ ... }, $args_list, sub{
    my $reply = shift;
    ...
  });

=head2 async

As an alternative to passing a callback or using a default callback, the
C<async> method returns a tied scalar that, when accessed, blocks until the
result is available. Note that if the task resulted in an error, it is thrown
when the async is fetched.

  my $async = $ar->async(sub{ ... }, $arg_list);

  if ($async eq 'slood') {
    ...
  }

See L<Argon::Async>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
