package AnyEvent::RabbitMQ::Fork::Channel;
$AnyEvent::RabbitMQ::Fork::Channel::VERSION = '0.5';
=head1 NAME

AnyEvent::RabbitMQ::Fork::Channel - Facade over L<AnyEvent::RabbitMQ::Channel>

=head1 SYNOPSIS

    my $ch = $rf->open_channel;
    $ch->declare_exchange(exchange => 'test_exchange');

=cut

use Moo;
use Types::Standard qw(Int Object Bool);

use namespace::clean;

=head1 DESCRIPTION

This module provides an API to L<AnyEvent::RabbitMQ::Channel> that is running in
a fork maintained by L<AnyEvent::RabbitMQ::Fork>. Note that this is a facade
and not a subclass. It does however attempt to honor the public interface of
the real thing.

There are some undocumented features of the real module that are not implemented
here. I leave that as an excercise for the reader to discover. At such a time as
those features appear to become formalized, I will expose them here.

=head1 ATTRIBUTES

=over

=item B<id> Numerical ID assigned by the connection object and used in
coordination with the server.

=item B<is_open> Indicator if this channel is open for use.

=item B<is_active> Indicator if the server has sent a C<Channel.Flow> frame as
a form of throttle control. Will be true if that is the case.

=item B<is_confirm> Indicator if the channel is in confirm mode, meaning the
server will Ack/Nack/Return every message published.

=back

=cut

has id         => (is => 'ro', isa => Int);
has is_open    => (is => 'ro', isa => Bool, default => 0);
has is_active  => (is => 'ro', isa => Bool, default => 0);
has is_confirm => (is => 'ro', isa => Bool, default => 0);
has connection => (
    is       => 'ro',
    isa      => Object,
    weak_ref => 1,
    handles  => { delegate => '_delegate' }
);

=head1 METHODS

Pretty well enumerated in L<AnyEvent::RabbitMQ::Channel>.

=cut

my @methods = qw(
  open
  close
  declare_exchange
  bind_exchange
  unbind_exchange
  delete_exchange
  declare_queue
  bind_queue
  unbind_queue
  purge_queue
  delete_queue
  publish
  consume
  cancel
  get
  ack
  qos
  confirm
  recover
  reject
  select_tx
  commit_tx
  rollback_tx
  );

foreach my $method (@methods) {
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        $self->delegate($method => $self->id, @_);
        return $self;
    };
}

=head1 AUTHOR

William Cox <mydimension@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014, the above named author(s).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
