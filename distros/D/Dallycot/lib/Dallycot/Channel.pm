package Dallycot::Channel;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: i/o channel base class

use utf8;
use Moose;
use Carp qw(croak);

sub can_send    {return}
sub can_receive {return}

sub send_data {
  my ( $self, @content ) = @_;

  # This needs to be written for an output channel
  my $class = ref $self || $self;
  croak "send() is not implemented for $class";
}

sub receive_data {
  my ($self) = @_;

  # This also needs to be written for an input channel
  # should return a promise that will be fulfilled with the
  # input when it arrives
  my $class = ref $self || $self;
  croak "receive() is not implemented for $class";
}

__PACKAGE__ -> meta -> make_immutable;

1;
