# NAME

Data::KSUID - K-Sortable Unique IDentifiers

# SYNOPSIS

    use Data::KSUID ':all';

    # Use the functional interface
    my $ksuid = create_ksuid;
    say ksuid_to_string($ksuid);

    # Or objects, if you're so inclined
    my $ksuid = Data::KSUID->new;
    say $ksuid->string;

# DESCRIPTION

KSUID are a globally unique identifier similar to UUIDs but designed to be
naturally sorted by generation timestamp and to have representations that
are easily postable across systems.

You can read more about KSUIDs and the rationale for their use in the
documentation for
[the original implementation](https://github.com/segmentio/ksuid)
by Segment.io and its
[accompanying blog post](https://segment.com/blog/a-brief-history-of-the-uuid).

This distribution aims to provide a fast and lightweight implementation of
these. It offers a functional interface based on that of [UUID::Tiny](https://metacpan.org/pod/UUID%3A%3ATiny), and
an object-oriented one that may be faster if your use-case entails running
multiple operations your KSUIDs.

# FUNCTIONAL INTERFACE

These functions avoid the overhead of creating an object, but since we have
no control over the data they are called on, they have to validate it before
running.

If you are going to be running multiple operations on your KSUIDs, the
object-oriented interface might be faster.

## create\_ksuid

    $bytes = create_ksuid(
        $timestamp // time,
        $payload   // <random bytes>
    );

Takes an optional timestamp and payload and returns the binary representation
of a KSUID. These binary strings are guaranteed to always be 20 bytes long.

If no timestamp is set, the current timestamp will be used. If no payload is
set, the KSUID will use a random set of bytes as provided by
 ["urandom" in Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom#urandom).

The provided timestamp should be a numeric UNIX timestamp, such as those
provided by core `time`. The provided payload must be 16 bytes long. If any
of these conditions is not met, this function will die.

For a similar function that returns a KSUID string, see ["create\_ksuid\_string"](#create_ksuid_string).

## create\_ksuid\_string

    $string = create_ksuid_string(
        $timestamp // time,
        $payload   // <random bytes>
    );

Takes an optional timestamp and payload and returns the string representation
of a KSUID. These strings are guaranteed to always be 27 characters long.

If no timestamp is set, the current timestamp will be used. If no payload is
set, the KSUID will use a random set of bytes as provided by
 ["urandom" in Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom#urandom).

The provided timestamp should be a numeric UNIX timestamp, such as those
provided by core `time`. The provided payload must be 16 bytes long. If any
of these conditions is not met, this function will die.

For a similar function that returns a binary KSUID, see ["create\_ksuid"](#create_ksuid).

## ksuid\_to\_string

    $string = ksuid_to_string($ksuid)

Takes a mandatory KSUID as a binary string and returns a base 62-encoded
representation of it as a 27-character string. This string will only use
upper and lowercase alphanumeric characters, so it should be safe to print
and store in any environment where these are valid.

If the provided KSUID is not one that ["is\_ksuid"](#is_ksuid) would accept, this
function will throw an exception.

For the reverse operation, see ["string\_to\_ksuid"](#string_to_ksuid).

## string\_to\_ksuid

    $ksuid = string_to_ksuid($string)

Takes a mandatory KSUID as a string and returns a binary representation of
it as a 20-byte string.

If the provided KSUID string is not one that ["is\_ksuid\_string"](#is_ksuid_string) would accept,
this function will throw an exception.

For the reverse operation, see ["ksuid\_to\_string"](#ksuid_to_string).

## time\_of\_ksuid

    $timestamp = time_of_ksuid($ksuid)

Takes a mandatory KSUID as a binary string and returns the timestamp that
was used when it was created as an integer like the one that you would get
from `time`.

If the provided KSUID is not one that ["is\_ksuid"](#is_ksuid) would accept, this
function will throw an exception.

## payload\_of\_ksuid

    $bytes = payload_of_ksuid($ksuid)

Takes a mandatory KSUID as a binary string and returns the 16-byte payload
that was used when it was created.

If the provided KSUID is not one that ["is\_ksuid"](#is_ksuid) would accept, this
function will throw an exception.

## next\_ksuid

    $next = next_ksuid($ksuid)

Takes a mandatory KSUID as a binary string and returns the binary string
representation of a different KSUID that will sort immediately after the
original one. This is useful in contexts were very many KSUIDs will be
generated in a short span, and they need to be guaranteed to sort in a
specific order.

If the provided KSUID is not one that ["is\_ksuid"](#is_ksuid) would accept, this
function will throw an exception.

For the reverse operation, see ["previous\_ksuid"](#previous_ksuid).

## previous\_ksuid

    $previous = previous_ksuid($ksuid)

Takes a mandatory KSUID as a binary string and returns the binary string
representation of a different KSUID that will sort immediately before the
original one. This is useful in contexts were very many KSUIDs will be
generated in a short span, and they need to be guaranteed to sort in a
specific order.

If the provided KSUID is not one that ["is\_ksuid"](#is_ksuid) would accept, this
function will throw an exception.

For the reverse operation, see ["next\_ksuid"](#next_ksuid).

## is\_ksuid

    $bool = is_ksuid($ksuid)

Checks whether the parameter that was provided is a binary KSUID and
returns a true or false value accordingly.

For validating KSUID strings, see ["is\_ksuid\_string"](#is_ksuid_string).

## is\_ksuid\_string

    $bool = is_ksuid_string($string)

Checks whether the parameter that was provided is the string representation
of a KSUID and returns a true or false value accordingly.

For validating KSUID strings, see ["is\_ksuid\_string"](#is_ksuid_string).

# OBJECT INTERFACE

The object-oriented interface incurs the overhead of creating an object, but
since have control over its internal state, its methods can skip most of the
validation when executed.

If you are simply going to be creating KSUIDs eg. for export, then the
functional interface might be faster.

## new

    $ksuid = Data::KSUID->new(
        $timestamp // time,
        $payload   // <random bytes>
    );

Takes an optional timestamp and payload and returns a KSUID object.

If no timestamp is set, the current timestamp will be used. If no payload is
set, the KSUID will use a random set of bytes as provided by
 ["urandom" in Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom#urandom).

The provided timestamp should be a numeric UNIX timestamp, such as those
provided by core `time`. The provided payload must be 16 bytes long. If any
of these conditions is not met, this function will die.

## parse

    $ksuid = Data::KSUID->parse($string)

Takes a mandatory KSUID as a string and returns an object for the KSUID it
represents.

If the provided KSUID string is not one that ["is\_ksuid\_string"](#is_ksuid_string) would accept,
this function will throw an exception.

For the reverse operation, see ["string"](#string).

## string

    $string = $ksuid->string

Returns a base 62-encoded representation of this KSUID as a 27-character
string. This string will only use upper and lowercase alphanumeric characters,
so it should be safe to print and store in any environment where these are
valid.

For a method that returns the binary representation of it, see ["bytes"](#bytes).

## bytes

    $bytes = $ksuid->bytes

Returns the binary representation of this KSUID as a 20-byte string.

For a method that returns the string representation of it, see ["string"](#string).

## time

    $timestamp = $ksuid->time

Returns the timestamp that was used when this KSUID was created as an integer
like the one that you would get from `time`.

## payload

    $bytes = $ksuid->payload

Returns the 16-byte payload that was used when this KSUID was created.

## next

    $next = $ksuid->next

Returns a KSUID object that will sort immediately after this one. This is
useful in contexts were very many KSUIDs will be generated in a short span,
and they need to be guaranteed to sort in a specific order.

For the reverse operation, see ["previous"](#previous).

## previous

    $previous = $ksuid->previous

Returns a KSUID object that will sort immediately before this one. This is
useful in contexts were very many KSUIDs will be generated in a short span,
and they need to be guaranteed to sort in a specific order.

For the reverse operation, see ["next"](#next).

# CONSTANTS

The following constants are available. These are not exported, but can be
used via their fully qualified names.

## MIN

The minimum value for a KSUID. A string of 20 null bytes.

## MAX

The maximum value for a KSUID. A string of 20 bytes set to `\xFF`.

## MIN\_STRING

The string representation of the minimum value of a KSUID. A string of
27 zeroes.

## MAX\_STRING

The string representation of the maximum value of a KSUID. Equivalent to
stringifying the value of ["MAX"](#max).

# SEE ALSO

- [https://github.com/segmentio/ksuid](https://github.com/segmentio/ksuid)
- [https://segment.com/blog/a-brief-history-of-the-uuid](https://segment.com/blog/a-brief-history-of-the-uuid)

# ACKNOWLEDGEMENTS

The internal codec used to serialise and deserialise KSUIDs is based on the
algorithm implemented in the original codebase by Achille Roussel.

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
