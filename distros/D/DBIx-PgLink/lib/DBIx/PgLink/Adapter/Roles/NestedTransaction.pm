package DBIx::PgLink::Adapter::Roles::NestedTransaction;

use Moose::Role;
use DBIx::PgLink::Logger;

# borrowed from DBIx::Roles::Transaction

has 'transaction_counter' => (
  isa     => 'Int',
  is      => 'rw',
  lazy    => 1,
  default => sub { 0 },
);

has 'transaction_status' => (
  isa     => 'Bool',
  is      => 'rw',
  lazy    => 1,
  default => sub { 1 },
);


around 'begin_work' => sub {
  my $next = shift;
  my $self = shift;

  my $cnt = $self->transaction_counter;

  $self->transaction_counter( $self->transaction_counter + 1);

  trace_msg('NOTICE', "begin_work: counter=".$self->transaction_counter.", status=".$self->transaction_status) 
    if trace_level >= 2;

  return $cnt ? 1 : $next->($self);
};


around 'rollback' => sub {
  my $next = shift;
  my $self = shift;

  $self->transaction_counter( $self->transaction_counter - 1);

  trace_msg('NOTICE', "rollback: counter=".$self->transaction_counter.", status=".$self->transaction_status) 
    if trace_level >= 2;

  if ($self->transaction_counter > 0) {
    my $status = $self->transaction_status;
    $self->transaction_status(0);
    return $status;
  } else {
    $self->transaction_status(1);
    $self->transaction_counter(0); # need more tests
    return $next->($self);
  }
};


around 'commit' => sub {
  my $next = shift;
  my $self = shift;

  $self->transaction_counter( $self->transaction_counter - 1);

  trace_msg('NOTICE', "commit: counter=".$self->transaction_counter.", status=".$self->transaction_status) 
    if trace_level >= 2;

  if ($self->transaction_counter > 0) {
    return $self->transaction_status;
  } elsif ($self->transaction_status) {
    return $next->($self);
  } else {
    $self->transaction_status(1);
    $self->transaction_counter(0); # need more tests
    return $self->rollback;
  }
};


1;
