package Bot::Backbone::SendPolicy::MinimumRepeatInterval;
$Bot::Backbone::SendPolicy::MinimumRepeatInterval::VERSION = '0.161950';
use v5.10;
use Moose;

with 'Bot::Backbone::SendPolicy';

use AnyEvent;

# ABSTRACT: Prevent any message from being repeated too often


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


has lingering_interval => (
    is          => 'ro',
    isa         => 'Num',
    predicate   => 'has_lingering_interval',
);


has cache_key => (
    is          => 'ro',
    isa         => 'CodeRef',
    required    => 1,
    default     => sub { sub { $_[0]->{text} } },
    traits      => [ 'Code' ],
    handles     => {
        'get_cache_key' => 'execute',
    },
);


has send_cache => (
    is          => 'ro',
    isa         => 'HashRef[ArrayRef[Num]]',
    required    => 1,
    default     => sub { +{} },
    traits      => [ 'Hash' ],
    handles     => {
        'list_cache_keys'     => 'keys',
        'delete_cache_key'    => 'delete',
        'last_send_times'     => 'get',
        'set_last_send_times' => 'set',
        'has_cache_key'       => 'defined',
    },
);


sub purge_send_cache {
    my $self = shift;

    my $now = AnyEvent->now;
    for my $key ($self->list_cache_keys) {
        my ($last_send, $orig_send) = @{ $self->last_send_times($key) };

        # Delete if it's been longer than interval since last send
        $self->delete_cache_key($key)
            if $last_send + $self->interval < $now;
    }
}


sub allow_send {
    my ($self, $options) = @_;

    $self->purge_send_cache;

    my %send = ( allow => 1 );
    my $now = AnyEvent->now;
    my $key = $self->get_cache_key($options);
    my $save = 1;
    my $after = 0;
    my ($last_send, $orig_send) = ($now, $now);

    if ($self->has_cache_key($key)) {

        # If there's already a cache key in place, don't save
        $save = 0;

        # Discard immediately if requested
        if ($self->discard) {
            $send{allow} = 0;
        }

        # Otherwise, determine how long to delay sending
        else {
            ($last_send, $orig_send) = @{ $self->last_send_times($key) };

            # Wait for whatever is left of the interval since the last send
            $send{after} = $after = ($last_send + $self->interval) - $now;

            # If we have a lingering interval, we need to modify the send cache
            if ($self->has_lingering_interval) {
                $save = 1;

                # The lingering interval has not been passed, so move the last
                # send date forward
                if ($now - $orig_send < $self->lingering_interval) {
                    $last_send = $now + $after;
                }

                # The lingering interval has passed, so move it back to the
                # original, which should guarantee it is purged next cycle
                else {
                    $last_send = $orig_send;
                }
            }

            # If the number of messages queued is too long, nevermind...
            $send{allow} = 0
                if $self->has_queue 
               and $after / $self->interval > $self->queue_length;
        }
    }

    $self->set_last_send_times($key, [ $last_send, $orig_send ]) if $save;
    return \%send;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::SendPolicy::MinimumRepeatInterval - Prevent any message from being repeated too often

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  send_policy dont_repeat_yourself => (
      MinimumRepeatInterval => {
          interval        => 5 * 60,
          discard         => 1,
          linger_interval => 60 * 60,
      },
  );

=head1 DESCRIPTION

This send policy will prevent a particular message text from being sent more frequently than the permitted L</interval>. 

For example, suppose you have a service which does a Wikipedia lookup each time someone uses a WikiWord and states the link and first sentence from the article. It would be terribly annoying if, during a heated discussion of this article, when the WikiWord were repeated often, if that resulted in the bot posting and re-posting that sentence and link over and over again. With this policy in place, you don't have to worry about that happening.

=head1 ATTRIBUTES

=head2 interval

This is the length of time in fractional seconds during which the bot is not permitted to repeat any particular message.

=head2 queue_length

This is the maximum number of messages that will be queued for later display before the messages will be discarded. If L</discard> is set to false, it is recommended that you set this value to something reasonable.

=head2 discard

When set to a true value, any messasge sent too soon will be discarded immediately. The default is false.

=head2 lingering_interval

The L</interval> determines how long the bot must wait before sending a duplicate message text. The lingering interval allows the normal interval to be extended with each new attempt to send the duplicate message text. The extension will occur according to the usual C<interval>, but will not be extended being the values set in fractional seconds on the C<lingering_interval>.

For example, suppose you have interval set to 5 seconds and lingering interval set to 20 seconds. The bot tries to send the message "blah" and then tries again 3 seconds later and then again 6 seconds after the original. Both of these followup attempts will blocked. Assume this continues at 3 second intervals for 60 seconds. All the messages will be blocked except that first message, the message coming at 21 seconds and 42 seconds.

=head2 cache_key

The documentation in this module fudges a little in how this works. It's actually more flexible than it might seem. Normally, this send policy works based upon the actual message text sent by the user. However, in some cases this might not be convenient. In case you want to make the send policy depend on some other aspect of the message other than the message text, just replace the default C<cache_key> with a new subroutine.

The given subroutine will be passed a single argument, the options hash reference sent to L</allow_send>. It must return a string (i.e., whatever is returned will be stringified). That string will be used as the cache key.

This is an advanced feature. If you can't think of a reason why you'd want to use it, you probably don't want to. This is why the rest of the documentation will assumes the message text, but it's really caching according to whatever this little subroutine returns.

=head2 send_cache

This is the actual structure used to determine how recently a particular message text was last sent. Each time the send policy is called, it will be purged of any keys that are no longer relevant.

It should be safe to save this structure using L<JSON> or L<YAML> or L<MongoDB> or L<Storable> or whatever you like and load it again, if you want the bot's C<send_cache> to survive restarts. However, the structure itself should be considered opaque and might change in a future release of L<Bot::Backbone>. It may even be removed altogether in a future release since there are lots of handy caching tools on the CPAN that might be used in place of this manual one.

=head1 METHODS

=head2 purge_send_cache

  $self->purge_send_cache;

This method may go away in a future release depending on the fate of L</send_cache>. In the meantime, however, this method is used clear the C<send_cache> of expired cache keys.

=head2 allow_send

This applies the send policy to the message.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
