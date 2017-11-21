package Argon::Manager;
# ABSTRACT: Entry-point Argon service providing intelligent task routing
$Argon::Manager::VERSION = '0.18';

use strict;
use warnings;
use Carp;
use Moose;
use Path::Tiny qw(path);
use AnyEvent;
use Argon::Client;
use Argon::Constants qw(:commands);
use Argon::Log;
use Argon::Marshal;
use Argon::Queue;
use Argon::Tracker;
use Argon::Util qw(K param);

extends qw(Argon::Server);

has assigned => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {{}},
);

has worker => (
  is      => 'rw',
  isa     => 'HashRef[Argon::SecureChannel]',
  default => sub {{}},
  traits  => ['Hash'],
  handles => {
    add_worker => 'set',
    get_worker => 'get',
    del_worker => 'delete',
    worker_ids => 'keys',
    workers    => 'values',
  },
);

has tracker => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub {{self => Argon::Tracker->new(capacity => 0)}},
);

has queue => (
  is       => 'rw',
  isa      => 'Argon::Queue',
  lazy     => 1,
  builder  => '_build_queue',
  handles  => {
    next_message  => 'get',
    queue_message => 'put',
    has_messages  => 'count',
  },
);

sub _build_queue {
  my $self = shift;
  if ($self->persist && $self->store->exists) {
    log_trace 'Loading message queue from saved copy';

    my $saved = $self->decode($self->load_file);
    my $queue = $saved->{queue};
    $queue->max($self->capacity);

    return $queue;
  }
  else {
    return Argon::Queue->new;
  }
}

has persist => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);

has store => (
  is       => 'ro',
  isa      => 'Maybe[Path::Tiny]',
  lazy     => 1,
  builder  => '_build_store',
  init_arg => undef,
  handles  => {
    save_file => 'spew_raw',
    load_file => 'slurp_raw',
  },
);

sub _build_store { path(shift->persist) }

after configure => sub {
  my $self = shift;
  $self->handles($HIRE,  K('_hire',  $self));
  $self->handles($QUEUE, K('_queue', $self));
};

sub DEMOLISH {
  my ($self, $global) = @_;
  $self->save_queue unless $global;
}

sub save_queue {
  my $self = shift;
  return unless $self->persist;
  log_trace 'Saving copy of message queue';

  my $saved = {
    queue => $self->queue,
  };

  my $data = encode($saved);
  $self->save_file($data);
}

sub capacity     { $_[0]->tracker->{self}->capacity }
sub has_capacity { $_[0]->tracker->{self}->has_capacity }

sub update_queue_capacity {
  my $self = shift;
  $self->queue->max($self->capacity * 3);
}

sub next_worker {
  my $self = shift;

  my @workers =
    sort { $self->tracker->{$a}->load <=> $self->tracker->{$b}->load }
    grep { $self->tracker->{$_}->has_capacity }
    $self->worker_ids;

  shift @workers;
}

sub assign {
  my ($self, $id, $msg) = @_;
  $self->get_worker($id)->send($msg);
  $self->tracker->{$id}->start($msg);
  $self->tracker->{self}->start($msg);
  $self->assigned->{$msg->id} = $id;
  log_trace 'worker %s assigned %s', $id, $msg->explain;
}

sub process_queue {
  my $self = shift;

  while ($self->has_capacity && $self->has_messages) {
    $self->assign($self->next_worker, $self->next_message);
  }

  $self->save_queue;
}

sub _queue {
  my ($self, $addr, $msg) = @_;
  if ($self->queue->is_full) {
    $self->send($msg->reply(cmd => $DENY, info => "No available capacity. Please try again later."));
  }
  else {
    $self->queue_message($msg);
    $self->process_queue;
  }
}

sub _collect {
  my ($self, $msg) = @_;
  my $id = delete $self->assigned->{$msg->id};
  $self->tracker->{$id}->finish($msg);
  $self->tracker->{self}->finish($msg);
  $self->send($msg);
  $self->process_queue;
}

sub _hire {
  my ($self, $addr, $msg) = @_;
  $self->send($msg->reply(cmd => $ACK));

  my $id  = $msg->token || croak 'Missing token: ' . $msg->explain;
  my $cap = $msg->info->{capacity};

  my $worker = $self->client->{$addr};
  $worker->on_msg(K('_collect', $self));
  $worker->on_close(K('_fire', $self, $id, $cap));

  $self->add_worker($id, $worker);

  $self->tracker->{$id} = Argon::Tracker->new(capacity => $cap);
  $self->tracker->{self}->add_capacity($cap);
  $self->update_queue_capacity;

  log_info 'New worker with identity %s added %d capacity (%d total)',
    $id, $cap, $self->capacity;
}

sub _fire {
  my ($self, $worker, $capacity) = @_;
  $self->tracker->{self}->remove_capacity($capacity);
  $self->del_worker($worker);
  delete $self->tracker->{$worker};

  $self->update_queue_capacity;

  my @msgids = grep { $self->assigned->{$_} eq $worker }
    keys %{$self->assigned};

  if (@msgids) {
    my $msg = 'The worker assigned to this task disconnected before completion.';
    $self->send(Argon::Message->error($msg, id => $_))
      foreach @msgids;
  }

  log_info 'Worker %s disconnected; capacity is down to %d',
    $worker,
    $self->capacity;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Manager - Entry-point Argon service providing intelligent task routing

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  use Argon::Manager;
  use AnyEvent;

  my $cv = AnyEvent->condvar;

  my $mgr = Argon::Manager->new(
    host    => 'localhost',
    port    => 8000,
    keyfile => 'path/to/secret',
  );

  $cv->recv;

=head1 DESCRIPTION

The entry point service with which workers are registered, to which clients
connect, and which provides task queueing services for the system.

For most use cases, this class need not be access directly; instead,
L<bin/ar-manager> provides a command-line interface to control the manager
process.

=head1 PUBLIC INTERFACE

Most relevant attributes and methods are documented in L<Argon::Server>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
