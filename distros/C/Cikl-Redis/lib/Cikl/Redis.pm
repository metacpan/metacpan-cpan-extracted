package Cikl::Redis;
use 5.014;
use strict;
use warnings;

our $VERSION = "0.01";

use strict;
use warnings;
use Mouse;
use Redis;
use Cikl::Client::Transport;
with 'Cikl::Client::Transport';
use namespace::autoclean;

has 'server' => (
  is => 'ro',
  isa => 'Str',
  default => 'localhost:6379'
);

has 'list' => (
  is => 'ro',
  isa => 'Str',
  default => 'cikl.event'
);

has 'conn' => (
  is => 'ro', 
  isa => 'Redis',
  init_arg => undef,
  lazy_build => 1
);

sub _build_conn {
  my $self = shift;
  return Redis->new(
    server => $self->server()
  );
}

sub shutdown_conn {
  my $self = shift;

  if ($self->has_conn()) {
    $self->conn->quit();
    $self->clear_conn();
  }
}

after 'shutdown' => sub {
    my $self = shift;

    $self->shutdown_conn();

    return 1;
};

sub _submit {
    my $self = shift;
    my $event = shift;

    my $body = $self->encode_event($event);
    $self->conn->rpush(
      $self->list(),
      $body
    );
    return undef;
}
__PACKAGE__->meta->make_immutable();
1;

__END__

=encoding utf-8

=head1 NAME

Cikl::Redis - It's new $module

=head1 SYNOPSIS

    use Cikl::Redis;

=head1 DESCRIPTION

Cikl::Redis is the Redis client transport module for Cikl.

=head1 LICENSE

Copyright (C) Mike Ryan.

See LICENSE file for details.

=head1 AUTHOR

Mike Ryan E<lt>falter@gmail.comE<gt>

=cut



