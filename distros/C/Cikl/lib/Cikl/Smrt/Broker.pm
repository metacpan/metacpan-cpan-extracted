package Cikl::Smrt::Broker;
use strict;
use warnings;
use Mouse;
use namespace::autoclean;
use Try::Tiny;

has 'builder' => (
  is => 'bare',
  isa => 'Cikl::EventBuilder',
  reader => '_builder',
  required => 1
);

has 'count' => (
  is => 'ro',
  isa => 'Num',
  writer => '_set_count',
  required => 1,
  default => 0,
  init_arg => undef
);

has 'count_failed' => (
  is => 'ro',
  isa => 'Num',
  writer => '_set_count_failed',
  required => 1,
  default => 0,
  init_arg => undef
);

has 'count_too_old' => (
  is => 'ro',
  isa => 'Num',
  writer => '_set_count_too_old',
  required => 1,
  default => 0,
  init_arg => undef
);

sub emit {
  my $self = shift;
  my $event_hash = shift;
  my $err;
  my $event;
  try {
    $event = $self->_builder->build_event($event_hash);
  } catch {
    $err = shift;
  };
  if ($err) {
    $self->_set_count_failed($self->count_failed() + 1);
    return;
  }
  if (defined($event)) {
    $self->_emit($event);
    $self->_set_count($self->count() + 1);
  } else {
    $self->_set_count_too_old($self->count_too_old() + 1);
    # It was too old.
  }
}

sub _emit {
  my $self = shift;
  die("_emit not implemented!");
}

__PACKAGE__->meta->make_immutable;

1;
