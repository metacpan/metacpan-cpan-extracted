# NAME

Algorithm::TokenBucket - Token bucket rate limiting algorithm

# SYNOPSIS

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

# DESCRIPTION

The Token Bucket algorithm is a flexible way of imposing a rate limit
against a stream of items. It is also very easy to combine several
rate-limiters in an `AND` or `OR` fashion.

Each bucket has a constant memory footprint because the algorithm is based
on the `information rate`. Other rate limiters may keep track of
_ALL_ incoming items in memory. It allows them to be more accurate.

FYI, the `conform`, `count`, `information rate`, and `burst size` terms
are taken from the [metering primitives](http://linux-ip.net/gl/tcng/node62.html)
page of the [Linux Traffic Control - Next Generation](http://linux-ip.net/gl/tcng/)
system documentation.

# INTERFACE

## METHODS

- new($$;$$)

    The constructor requires at least the `rate of information` in items per
    second and the `burst size` in items as its input parameters. It can also
    take the current token counter and last check time but this usage is mostly
    intended for restoring a saved bucket. See ["state()"](#state).

- state()

    Returns the state of the bucket as a list. Use it for storing purposes.
    Buckets also natively support freezing and thawing with [Storable](https://metacpan.org/pod/Storable) by
    providing `STORABLE_*` callbacks.

- conform($)

    This method returns true if the bucket contains at least _N_ tokens and
    false otherwise. In the case that it is true, it is allowed to transmit or
    process _N_ items (not exactly right because _N_ can be fractional) from
    the stream. A bucket never conforms to an _N_ greater than `burst size`.

- count($)

    This method removes _N_ (or all if there are fewer than _N_ available)
    tokens from the bucket. It does not return a meaningful value.

- until($)

    This method returns the number of seconds until _N_ tokens can be removed
    from the bucket. It is especially useful in multitasking environments like
    [POE](https://metacpan.org/pod/POE) where you cannot busy-wait. One can safely schedule the next
    `conform($N)` check in `until($N)` seconds instead of checking
    repeatedly.

    Note that `until()` does not take into account `burst size`. This means
    that a bucket will not conform to _N_ even after sleeping for `until($N)`
    seconds if _N_ is greater than `burst size`.

- get\_token\_count()

    Returns the current number of tokens in the bucket. This method may be
    useful for inspection or debugging purposes. You should not examine
    the state of the bucket for rate limiting purposes.

    This number will frequently be fractional so it is not exactly a
    "count".

# EXAMPLES

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

Now, let's fix the CPU-hogging example from ["SYNOPSIS"](#synopsis) using
the ["until($)"](#until) method.

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

# BUGS

Documentation lacks the actual algorithm description. See links or read
the source (there are about 20 lines of sparse Perl in several subs).

`until($N)` does not return infinity if `$N` is greater than `burst
size`. Sleeping for infinity seconds is both useless and hard to debug.

# ACKNOWLEDGMENTS

Yuval Kogman contributed the ["until($)"](#until) method, proper [Storable](https://metacpan.org/pod/Storable) support
and other things.

Alexey Shrub contributed the ["get\_token\_count()"](#get_token_count) method.

Paul Cochrane contributed various documentation and infrastructure fixes.

# COPYRIGHT AND LICENSE

This software is copyright (C) 2016 by Alex Kapranoff.

This is free software; you can redistribute it and/or modify it under
the terms GNU General Public License version 3.

# AUTHOR

Alex Kapranoff, &lt;alex@kapranoff.ru>

# SEE ALSO

- https://web.archive.org/web/20050320184218/http://www.eecs.harvard.edu/cs143/assignments/pa1/
- http://en.wikipedia.org/wiki/Token\_bucket
- http://linux-ip.net/gl/tcng/node54.html
- http://linux-ip.net/gl/tcng/node62.html
- [Schedule::RateLimit](https://metacpan.org/pod/Schedule::RateLimit)
- [Algorithm::FloodControl](https://metacpan.org/pod/Algorithm::FloodControl)
- [Object::RateLimiter](https://metacpan.org/pod/Object::RateLimiter)
