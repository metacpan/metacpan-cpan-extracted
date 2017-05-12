package Cikl::RabbitMQ;
use 5.008005;
use strict;
use warnings;
use Mouse;
use Cikl::Client::Transport;
require Net::RabbitFoot;

our $VERSION = "0.01";

with 'Cikl::Client::Transport';
use namespace::autoclean;

has 'host' => (
  is => 'ro',
  isa => 'Str',
  default => 'localhost'
);

has 'port' => (
  is => 'ro',
  isa => 'Num',
  default => 5572
);

has 'username' => (
  is => 'ro',
  isa => 'Str',
  default => 'guest'
);

has 'password' => (
  is => 'ro',
  isa => 'Str',
  default => 'guest'
);

has 'vhost' => (
  is => 'ro',
  isa => 'Str',
  default => '/'
);

has 'submit_key' => (
  is => 'ro', 
  isa => 'Str',
  default => 'cikl.event'
);

has 'submit_exchange' => (
  is => 'ro', 
  isa => 'Str',
  default => ''
);

has 'amqp' => (
  is => 'ro', 
  isa => 'Net::RabbitFoot',
  init_arg => undef,
  lazy_build => 1
);

sub _build_amqp {
  my $self = shift;
  return Net::RabbitFoot->new()->load_xml_spec()->connect(
    host => $self->host(),
    port => $self->port(),
    user => $self->username(),
    pass => $self->password(),
    vhost => $self->vhost()
  );
}

sub shutdown_amqp {
  my $self = shift;

  if ($self->has_amqp()) {
    $self->amqp->close();
    $self->clear_amqp();
  }
}

has 'channel' => (
  is => 'ro', 
  init_arg => undef,
  lazy_build => 1
);

sub _build_channel {
  my $self = shift;
  return $self->amqp()->open_channel();
}

after 'shutdown' => sub {
    my $self = shift;

    if ($self->has_channel()) {
      $self->channel->close();
      $self->clear_channel();
    }

    $self->shutdown_amqp();

    return 1;
};

sub _submit {
    my $self = shift;
    my $event = shift;

    my $body = $self->encode_event($event);
    $self->channel->publish(
      exchange => $self->submit_exchange,
      routing_key => $self->submit_key,
      body => $body 
    );
    return undef;
}
__PACKAGE__->meta->make_immutable();

1;

__END__

=encoding utf-8

=head1 NAME

Cikl::RabbitMQ - It's new $module

=head1 SYNOPSIS

    use Cikl::RabbitMQ;

=head1 DESCRIPTION

Cikl::RabbitMQ is the RabbitMQ client transport module for Cikl.

=head1 LICENSE

Copyright (C) Mike Ryan.

See LICENSE file for details.

=head1 AUTHOR

Mike Ryan E<lt>falter@gmail.comE<gt>

=cut

