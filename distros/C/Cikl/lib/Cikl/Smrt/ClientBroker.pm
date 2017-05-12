package Cikl::Smrt::ClientBroker;
use strict;
use warnings;
use Mouse;
use namespace::autoclean;
extends 'Cikl::Smrt::Broker';

has 'client' => (
  is => 'bare',
  isa => 'Cikl::Client',
  reader => '_client',
  required => 1
);

sub _emit {
  my $self = shift;
  my $event = shift;
  my ($err, $ret) = $self->_client->submit($event);
  if ($err) {
    die($err);
  }
}

__PACKAGE__->meta->make_immutable;

1;

