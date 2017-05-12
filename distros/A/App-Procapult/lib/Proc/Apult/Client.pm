package Proc::Apult::Client;

use strictures 1;
use Moo;

has master => (is => 'ro', required => 1, weak_ref => 1);

has stream => (is => 'ro', required => 1, clearer => 1);

sub BUILD {
  my ($self) = @_;
  $self->stream->configure(
    on_read => $self->curry::weak::handle_read,
    on_closed => $self->curry::weak::handle_closed
  );
}

sub handle_read {
  my ($self, undef, $buffref) = @_;
  while ($$buffref =~ s/^(.*)\n//) {
    $self->handle_command($1);
  }
}

sub handle_command {
  my ($self, $command) = @_;
  my ($name, $args) = $command =~ /^(\w+)(?: (.*))?$/;
  unless ($name) {
    $self->stream->write("ERROR: unparseable\n");
    return;
  }
  my $meth = $self->can("do_${name}");
  unless ($meth) {
    $self->stream->write("ERROR: no such command ${name}\n");
    return;
  }
  $self->$meth($args);
}

sub handle_closed {
  my ($self) = @_;
  $self->clear_stream;
  $self->master->loop->later($self->master->curry::remove_client($self));
}

sub do_start {
  my ($self, $start) = @_;
  unless (defined $start and length $start) {
    $self->stream->write("ERROR: nothing to start\n");
    return;
  }
  if (my $err = $self->master->launcher_start($start)) {
    $self->stream->write("${err}\n");
  }
  return;
}

sub do_stop {
  my ($self) = @_;
  if (my $err = $self->master->launcher_stop) {
    $self->stream->write("${err}\n");
  }
  return;
}

sub do_die {
  my ($self) = @_;
  $self->master->commit_harakiri;
}

sub send_launcher_status {
  my ($self, $new_status) = @_;
  $self->stream and $self->stream->write("STATUS: ${new_status}\n");
}

1;
