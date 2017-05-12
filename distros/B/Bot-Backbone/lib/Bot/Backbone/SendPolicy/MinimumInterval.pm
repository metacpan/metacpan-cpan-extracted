package Bot::Backbone::SendPolicy::MinimumInterval;
$Bot::Backbone::SendPolicy::MinimumInterval::VERSION = '0.161950';
use v5.10;
use Moose;

with 'Bot::Backbone::SendPolicy';

use AnyEvent;

# ABSTRACT: Prevent any message from being delivered too soon


has interval => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
);


has queue_length => (
    is          => 'ro',
    isa         => 'Int',
    predicate   => 'has_queue',
);


has discard => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);


has last_send_time => (
    is          => 'rw',
    isa         => 'Num',
    predicate   => 'has_last_send_time',
);


sub _too_soon {
    my $self = shift;
    my $now = AnyEvent->now;

    return 0 
        unless $self->has_last_send_time;

    return $self->last_send_time + $self->interval
        if ($self->last_send_time > $now)
        or ($now - $self->last_send_time < $self->interval);

    return 0;
}

sub allow_send {
    my ($self, $options) = @_;

    my %send = ( allow => 1 );
    my $now = AnyEvent->now;
    my $too_soon = $self->_too_soon;

    my $save = 1;
    if ($too_soon) {

        # Messages coming too fast should be thrown away
        if ($self->discard) {
            $save = 0;
            $send{allow} = 0;
        }

        # Messages coming too fast should be postponed 
        else {
            $send{after} = $too_soon - $now;

            # If the number of messages queued is too long, nevermind...
            $send{allow} = 0
                if $self->has_queue 
               and $send{after} / $self->interval > $self->queue_length;
        }
    }

    $self->last_send_time($too_soon || $now) if $save;
    return \%send;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::SendPolicy::MinimumInterval - Prevent any message from being delivered too soon

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  send_policy no_flooding => (
      MinimumInterval => { 
          interval     => 1.5,
          discard      => 1,
          queue_length => 5,
      },
  );

=head1 DESCRIPTION

This send policy will prevent any message from being sent more frequently than the permitted L</interval>. Messages sent more frequently than this will either be delayed to match the interval or discarded.

=head1 ATTRIBUTES

=head2 interval

This is the fractional number of seconds that must pass between each message sent. This attribute is required. The number must be positive (obviously).

=head2 queue_length

This is the number of items that will be queued up before additional items will be discarded. 

For example, if L</interval> were set to 1 second and C<queue_length> to 10 and a burst of 100 items happened within 1 second, only the first 10 would be sent, 1 per second. The other 90 items would be discarded. There's a slight fudge factor here due to times, so you might see a few more actually sent depending on how much delay happens in handling events.

If L</discard> is set to false, it is recommended that you set this value to something reasonable.

=head2 discard

If set to true, any message sent more frequently than the L</interval> will be immediately discarded. This is false by default.

=head1 last_send_time

This will be set each time the policy encounters a message. If L</discard> is false, this value may move into the future to signify the time at which the last queued message will be sent.

=head1 METHODS

=head2 allow_send

Applies the configured policy to the given message.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
