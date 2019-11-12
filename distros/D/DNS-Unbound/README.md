# NAME

DNS::Unbound - libunbound in Perl

# SYNOPSIS

    my $dns = DNS::Unbound->new()->set_option( verbosity => 2 );

    # This appears to be safe:
    $dns->enable_threads();

    my $verbosity = $dns->get_option( 'verbosity' );

    $dns->set_option( verbosity => 1 + $verbosity );

Synchronous queries:

    my $res_hr = $dns->resolve( 'cpan.org', 'NS' );

    # See below about encodings in “data”.
    my @ns = map { $dns->decode_name($_) } @{ $res_hr->data() };

Asynchronous queries use [the “Promise” pattern](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises):

    my $query1 = $dns->resolve_async( 'usa.gov', 'A' )->then(
        sub { my $data = shift()->data(); ... },  # success handler
        sub { ... },                              # failure handler
    );

    my $query2 = $dns->resolve_async( 'in-addr.arpa', 'NS' )->then(
        sub { ... },
        sub { ... },
    );

    # As an alternative to wait(), see below for documentation on
    # the fd(), poll(), and process() methods.

    $dns->wait();

See `examples/` in the distribution for demonstrations of
making this module interface with [AnyEvent](https://metacpan.org/pod/AnyEvent) or [IO::Async](https://metacpan.org/pod/IO::Async).

# DESCRIPTION

This library is a Perl interface to NLNetLabs’s widely-used
[Unbound](https://nlnetlabs.nl/projects/unbound/) recursive DNS resolver.

# METHODS

## _CLASS_->new()

Instantiates this class.

## $result\_hr = _OBJ_->resolve( $NAME, $TYPE \[, $CLASS \] )

Runs a synchronous query for a given $NAME and $TYPE. $TYPE may be
expressed numerically or, for convenience, as a string. $CLASS is
optional and defaults to 1 (`IN`), which is probably what you want.

Returns a [DNS::Unbound::Result](https://metacpan.org/pod/DNS::Unbound::Result) instance.

**NOTE:** libunbound doesn’t seem to offer effective controls for
timing out a synchronous query.
If timeouts are relevant for you, you probably need
to use `resolve_async()` instead.

## $query = _OBJ_->resolve\_async( $NAME, $TYPE \[, $CLASS \] );

Like `resolve()` but starts an asynchronous query rather than a
synchronous one.

This returns an instance of [DNS::Unbound::AsyncQuery](https://metacpan.org/pod/DNS::Unbound::AsyncQuery).

[See below](#methods-for-dealing-with-asynchronous-queries) for
the methods you’ll need to use in tandem with this one.

## _OBJ_->enable\_threads()

Sets _OBJ_’s asynchronous queries to use threads rather than forking.
Off by default. Throws an exception if called after an asynchronous query has
already been sent.

Returns _OBJ_.

**NOTE:** Despite Perl’s iffy relationship with threads, this appears
to work without issue.

## _OBJ_->set\_option( $NAME => $VALUE )

Sets a configuration option. Returns _OBJ_.

Note that this is basically just a passthrough to the underlying
`ub_ctx_set_option()` function and is thus subject to the same limitations
as that function; for example, you can’t set `verbosity` after the
configuration has been “finalized”. (So use `debuglevel()` for that
instead.)

## $value = _OBJ_->get\_option( $NAME )

Gets a configuration option’s value.

## _OBJ_->debuglevel( $LEVEL )

Sets the debug level (an integer). Returns _OBJ_.

As of libunbound v1.9.2, this is just a way to set the `verbosity`
option regardless of whether the configuration is finalized.

## _OBJ_->debugout( $FD\_OR\_FH )

Accepts a file descriptor or Perl filehandle and designates that
as the destination for libunbound diagnostic information.

Returns _OBJ_.

## $str = _CLASS_->unbound\_version()

Gives the libunbound version string.

# METHODS FOR DEALING WITH ASYNCHRONOUS QUERIES

Unless otherwise noted, the following methods correspond to their
equivalents in libunbound.

## _OBJ_->poll()



## _OBJ_->fd()



## _OBJ_->wait()



## _OBJ_->process()



## _OBJ_->count\_pending\_queries()

Returns the number of outstanding asynchronous queries.

# CONVENIENCE FUNCTIONS

The following may be called either as object methods or as static
functions (but not as class methods). In addition to these,
[Socket](https://metacpan.org/pod/Socket) provides the `inet_ntoa()` and `inet_ntop()`
functions for decoding the values of `A` and `AAAA` records.

**NOTE:** Consider parsing [DNS::Unbound::Result](https://metacpan.org/pod/DNS::Unbound::Result)’s `answer_packet()`
with [Net::DNS::Packet](https://metacpan.org/pod/Net::DNS::Packet) as a more robust, albeit heavier, way to
parse query result data.

## $decoded = decode\_name($encoded)

Decodes a DNS name. Useful for, e.g., `NS`, `CNAME`, and `PTR` query
results.

Note that this function’s return will normally include a trailing `.`
because of the trailing NUL byte in an encoded DNS name. This is normal
and expected.

## $strings\_ar = decode\_character\_strings($encoded)

Decodes a list of character-strings into component strings,
returned as an array reference. Useful for `TXT` query results.

# LICENSE & COPYRIGHT

Copyright 2019 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.

# REPOSITORY

[https://github.com/FGasper/p5-DNS-Unbound](https://github.com/FGasper/p5-DNS-Unbound)

# THANK YOU

Special thanks to [ATOOMIC](https://metacpan.org/author/ATOOMIC) for
making some helpful review notes.
