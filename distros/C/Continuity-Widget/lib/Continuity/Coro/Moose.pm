package Continuity::Coro::Moose;

use Moose::Role;
use Continuity::Coro::Continuation;

has 'cont'   => (is => 'rw');
has 'output' => (is => 'rw');
has 'input'  => (is => 'rw');

sub process {
  my ($self, $input) = @_;
  $self->input($input);
  $self->{cont} ||= continuation { while(1) { $self->main } };
  $self->{cont}->();
  return $self->output;
}

sub next {
  my ($self, $output) = @_;
  $self->output($output);
  yield;
  return $self->input;
}

1;

