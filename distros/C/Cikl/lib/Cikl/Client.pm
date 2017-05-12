package Cikl::Client;

use strict;
use warnings;
use Mouse;
use namespace::autoclean;
use Try::Tiny;
use Config::Simple;
use Cikl::Client::Transport;

has 'transport' => (
  is => 'ro',
  isa => 'Cikl::Client::Transport',
  required => 1,
  predicate => 'has_transport',
  clearer => 'clear_transport'
);

sub DEMOLISH {
    my $self = shift;
    $self->shutdown();
}

sub shutdown {
    my $self = shift;
    if ($self->has_transport()) {
      $self->transport()->shutdown();
      $self->clear_transport();
    }
    return 1;
}

sub submit {
    my $self = shift;
    my $event = shift;

    return $self->transport()->_submit($event);
}    

__PACKAGE__->meta->make_immutable();
1;
