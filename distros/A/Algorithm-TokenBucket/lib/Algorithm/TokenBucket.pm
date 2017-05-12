package Algorithm::TokenBucket;

use 5.008;

use warnings;
use strict;

our $VERSION = 0.38;

use Time::HiRes qw/time/;

=head1 NAME

Algorithm::TokenBucket - Token bucket rate limiting algorithm

=head1 SYNOPSIS

    use Algorithm::TokenBucket;

    # configure a bucket to limit a stream up to 100 items per hour
    # with bursts of 5 items max
    my $bucket = Algorithm::TokenBucket->new(100 / 3600, 5);

    # wait until we are allowed to process 3 items
    until ($bucket->conform(3)) {
        sleep 0.1;
        # do things
    }

    # process 3 items because we now can
    process(3);

    # leak (flush) bucket
    $bucket->count(3);  # same as $bucket->count(1) for 1..3;

    if ($bucket->conform(10)) {
        die;
        # because a bucket with the burst size of 5
        # will never conform to 10
    }

    my $time = Time::HiRes::time;
    while (Time::HiRes::time - $time < 7200) {  # two hours
        # be bursty
        if ($bucket->conform(5)) {
            process(5);
            $bucket->count(5);
        }
    }
    # we're likely to have processed 200 items (and hogged CPU)

    Storable::store $bucket, 'bucket.stored';
    my $bucket1 =
        Algorithm::TokenBucket->new(@{Storable::retrieve('bucket.stored')});

=head1 DESCRIPTION

The Token Bucket algorithm is a flexible way of imposing a rate limit
against a stream of items. It is also very easy to combine several
rate-limiters in an C<AND> or C<OR> fashion.

Each bucket has a constant memory footprint because the algorithm is based
on the C<information rate>. Other rate limiters may keep track of
I<ALL> incoming items in memory. It allows them to be more accurate.

FYI, the C<conform>, C<count>, C<information rate>, and C<burst size> terms
are taken from the L<metering primitives|http://linux-ip.net/gl/tcng/node62.html>
page of the L<Linux Traffic Control - Next Generation|http://linux-ip.net/gl/tcng/>
system documentation.

=head1 INTERFACE

=cut

use fields qw/info_rate burst_size _tokens _last_check_time/;

=head2 METHODS

=over 4

=item new($$;$$)

The constructor requires at least the C<rate of information> in items per
second and the C<burst size> in items as its input parameters. It can also
take the current token counter and last check time but this usage is mostly
intended for restoring a saved bucket. See L</state()>.

=cut

sub new {
    my $class   = shift;
    fields::new($class)->_init(@_);
}

sub _init {
    my Algorithm::TokenBucket $self = shift;

    @$self{qw/info_rate burst_size _tokens _last_check_time/} = @_;
    $self->{_last_check_time} ||= time;
    $self->{_tokens} ||= 0;

    return $self;
}

=item state()

Returns the state of the bucket as a list. Use it for storing purposes.
Buckets also natively support freezing and thawing with L<Storable> by
providing C<STORABLE_*> callbacks.

=cut

sub state {
    my Algorithm::TokenBucket $self = shift;

    return @$self{qw/info_rate burst_size _tokens _last_check_time/};
}

use constant PACK_FORMAT => "d4";   # "F4" is not 5.6 compatible

sub STORABLE_freeze {
    my ($self, $cloning) = @_;
    return pack(PACK_FORMAT(), $self->state);
}

sub STORABLE_thaw {
    my ($self, $cloning, $state) = @_;
    return $self->_init(unpack(PACK_FORMAT(), $state));
}

sub _token_flow {
    my Algorithm::TokenBucket $self = shift;

    my $time = time;

    $self->{_tokens} +=
        ($time - $self->{_last_check_time}) * $self->{info_rate};

    if ($self->{_tokens} > $self->{burst_size}) {
        $self->{_tokens} = $self->{burst_size};
    }

    $self->{_last_check_time} = $time;
}

=item conform($)

This method returns true if the bucket contains at least I<N> tokens and
false otherwise. In the case that it is true, it is allowed to transmit or
process I<N> items (not exactly right because I<N> can be fractional) from
the stream. A bucket never conforms to an I<N> greater than C<burst size>.

=cut

sub conform {
    my Algorithm::TokenBucket $self = shift;
    my $size = shift;

    $self->_token_flow;

    return $self->{_tokens} >= $size;
}

=item count($)

This method removes I<N> (or all if there are fewer than I<N> available)
tokens from the bucket. It does not return a meaningful value.

=cut

sub count {
    my Algorithm::TokenBucket $self = shift;
    my $size = shift;

    $self->_token_flow;

    ($self->{_tokens} -= $size) < 0 and $self->{_tokens} = 0;
}

=item until($)

This method returns the number of seconds until I<N> tokens can be removed
from the bucket. It is especially useful in multitasking environments like
L<POE> where you cannot busy-wait. One can safely schedule the next
C<< conform($N) >> check in C<< until($N) >> seconds instead of checking
repeatedly.

Note that C<until()> does not take into account C<burst size>. This means
that a bucket will not conform to I<N> even after sleeping for C<< until($N) >>
seconds if I<N> is greater than C<burst size>.

=cut

sub until {
    my Algorithm::TokenBucket $self = shift;
    my $size = shift;

    $self->_token_flow;

    if ($self->{_tokens} >= $size) {
        # can conform() right now
        return 0;
    } else {
        my $needed = $size - $self->{_tokens};
        return ($needed / $self->{info_rate});
    }
}

=item get_token_count()

Returns the current number of tokens in the bucket. This method may be
useful for inspection or debugging purposes. You should not examine
the state of the bucket for rate limiting purposes.

This number will frequently be fractional so it is not exactly a
"count".

=cut

sub get_token_count {
    my Algorithm::TokenBucket $self = shift;
    $self->_token_flow;
    return $self->{_tokens};
}

1;
__END__

=back

=head1 EXAMPLES

Imagine a rate limiter for a mail sending application. We would like to
allow 2 mails per minute but no more than 20 mails per hour.

    my $rl1 = Algorithm::TokenBucket->new(2/60, 1);
    my $rl2 = Algorithm::TokenBucket->new(20/3600, 10);
        # "bursts" of 10 to ease the lag but $rl1 enforces
        # 2 per minute, so it won't flood

    while (my $mail = get_next_mail) {
        until ($rl1->conform(1) && $rl2->conform(1)) {
            busy_wait;
        }

        $mail->take_off;
        $rl1->count(1); $rl2->count(1);
    }

Now, let's fix the CPU-hogging example from L</SYNOPSIS> using
the L</until($)> method.

    my $bucket = Algorithm::TokenBucket->new(100 / 3600, 5);
    my $time = Time::HiRes::time;
    while (Time::HiRes::time - $time < 7200) {  # two hours
        # be bursty
        Time::HiRes::sleep $bucket->until(5);
        if ($bucket->conform(5)) {  # should always be true
            process(5);
            $bucket->count(5);
        }
    }
    # we're likely to have processed 200 items (without hogging the CPU)

=head1 BUGS

Documentation lacks the actual algorithm description. See links or read
the source (there are about 20 lines of sparse Perl in several subs).

C<until($N)> does not return infinity if C<$N> is greater than C<burst
size>. Sleeping for infinity seconds is both useless and hard to debug.

=head1 ACKNOWLEDGMENTS

Yuval Kogman contributed the L</until($)> method, proper L<Storable> support
and other things.

Alexey Shrub contributed the L</get_token_count()> method.

Paul Cochrane contributed various documentation and infrastructure fixes.

=head1 COPYRIGHT AND LICENSE

This software is copyright (C) 2016 by Alex Kapranoff.

This is free software; you can redistribute it and/or modify it under
the terms GNU General Public License version 3.

=head1 AUTHOR

Alex Kapranoff, E<lt>alex@kapranoff.ruE<gt>

=head1 SEE ALSO

=over 4

=item https://web.archive.org/web/20050320184218/http://www.eecs.harvard.edu/cs143/assignments/pa1/

=item http://en.wikipedia.org/wiki/Token_bucket

=item http://linux-ip.net/gl/tcng/node54.html

=item http://linux-ip.net/gl/tcng/node62.html

=item L<Schedule::RateLimit>

=item L<Algorithm::FloodControl>

=item L<Object::RateLimiter>

=back

=cut
