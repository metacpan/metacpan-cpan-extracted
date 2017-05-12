package Proc::Apult::Launcher;

use strictures 2;
use IO::Async::Process;
use Object::Tap;
use curry;
use Moo;

has master => (is => 'ro', required => 1, weak_ref => 1);

has current_status => (is => 'rw', default => 'stopped');

has running_process => (is => 'rwp', clearer => '_clear_running_process');

sub start {
  my ($self, $start) = @_;
  return 'ERROR: already '.$self->current_status if $self->running_process;
  my $pid = $self->_set_running_process(
    IO::Async::Process->new(
      command => $start,
      on_finish => $self->curry::weak::notify_stopped,
    )->$_tap(sub {
      $self->master->loop->add($_[0])
    })
  )->pid;
  return 'ERROR: failure to fire' unless defined($pid);
  $self->notify(started => $pid => $start);
  return;
}

sub stop {
  my ($self, $signal) = @_;
  return 'ERROR: already '.$self->current_status unless $self->running_process;
  $self->running_process->kill($signal||'HUP');
  return;
}

sub notify_stopped {
  my ($self, $exit_code) = @_;
  $self->_clear_running_process;
  $self->notify('stopped');
}

sub notify {
  my ($self, @status) = @_;
  $self->master->broadcast_launcher_status(
    $self->current_status(join ' ', @status)
  );
}

1;
