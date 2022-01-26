# NAME

Data::ULID - Universally Unique Lexicographically Sortable Identifier

# SYNOPSIS

    use Data::ULID qw/ulid binary_ulid ulid_date/;

    my $ulid = ulid();  # e.g. 01ARZ3NDEKTSV4RRFFQ69G5FAV
    my $bin_ulid = binary_ulid($ulid);
    my $datetime_obj = ulid_date($ulid);  # e.g. 2016-06-13T13:25:20
    my $uuid = ulid_to_uuid($ulid);
    my $ulid2 = uuid_to_ulid($uuid);

# DESCRIPTION

## Background

This is an implementation in Perl of the ULID identifier type introduced by
Alizain Feerasta. The original implementation (in Javascript) can be found at
[https://github.com/alizain/ulid](https://github.com/alizain/ulid).

ULIDs have several advantages over UUIDs in many contexts. The advantages
include:

- Lexicographically sortable
- The canonical representation is shorter than UUID (26 vs 36 characters)
- Case insensitve and safely chunkable.
- URL-safe
- Timestamp can always be easily extracted if so desired.
- Limited compatibility with UUIDS, since both are 128-bit formats.
Some conversion back and forth is possible.

## Canonical representation

The canonical representation of a ULID is a 26-byte, base32-encoded string
consisting of (1) a 10-byte timestamp with millisecond-resolution; and (2) a
16-byte random part.

Without paramters, the `ulid()` function returns a new ULID in the canonical
representation, with the current time (up to the nearest millisecond) in the
timestamp part.

    $ulid = ulid();

Given a DateTime object as parameter, the function will set the timestamp part
based on that:

    $ulid = ulid($datetime_obj);

Given a binary ULID as parameter, it returns the same ULID in canonical
format:

    $ulid = ulid($binary_ulid);

## Binary representation

The binary representation of a ULID is 16 octets long, with each component in
network byte order (most significant byte first). The components are (1) a
48-bit (6-byte) timestamp in a 32-bit and a 16-bit chunk; (2) an 80-bit
(10-byte) random part in a 16-bit and two 32-bit chunks.

The `binary_ulid()` function returns a ULID in binary representation. Like
`ulid()`, it can take no parameters or a DateTime, but it can also take a
ULID in the canonical representation and convert it to binary:

    $binary_ulid = binary_ulid($canonical_ulid);

## Datetime extraction

The `ulid_date()` function takes a ULID (canonical or binary) and returns
a DateTime object corresponding to the timestamp it encodes.

    $datetime = ulid_date($ulid);

## UUID conversion

Very limited conversion between UUIDs and ULIDs is provided.

In order to convert a UUID to ULID:

    $ulid = uuid_to_ulid($uuid);

Both binary and hexadecimal UUIDs (with or without separators) are accepted.
The return value is a ULID string in the canonical Base32 form. Note that the
"timestamp" of such a ULID is not to be relied upon.

A ULID can also be converted to a UUID:

    $uuid = ulid_to_uuid($binary_or_canonical_ulid);

The UUID returned by this function is a string in the standard hyphenated
hexadecimal format. Note that the variant and version indicators of such a
UUID are meaningless.

## UUID conversion limitations

Since both ULIDs and UUIDs are 128-bit, conversion back and forth is possible
in principle. However, the two formats have different semantics. Also, any
given UUID version has at most 122 bits of variance (4 bits being reserved as
variant and version indicators), while all 128 bits of the ULID format can
vary without violating the format description. This means that the conversion
can never be made perfect.

It would be possible to maintain the approximate timestamp of a Version 1 UUID
when converting to ULID, as well as to keep the timestamp of a ULID when
converting to UUID. However, since many UUIDs are not of Version 1, and given
the different semantics of the two formats, the conversion provided by this
module is much simpler and does not preserve the timestamps. In fact, about
the only desirable property that the chosen conversion method has is that it
is uniformly bidirectional, i.e.

    $uuid eq ulid_to_uuid(ulid_to_uuid($uuid))

and

    $ulid eq uuid_to_ulid(ulid_to_uuid($ulid))

This approach has two immediate consequences:

1. The "timestamps" of ULIDs created by converting UUIDs are meaningless.
2. The variant and version indicators of UUIDs created by converting ULIDs are
similarly wrong. Such UUIDs should only be used in contexts where no checking
of these fields will be performed and no attempt will be made to extract or
validate non-random information (i.e. timestamp, MAC address or namespace).

# DEPENDENCIES

[Math::Random::Secure](https://metacpan.org/pod/Math::Random::Secure), [Encode::Base32::GMP](https://metacpan.org/pod/Encode::Base32::GMP).

# AUTHOR

Baldur Kristinsson, December 2016

# LICENSE

This is free software. It may be copied, distributed and modified under the
same terms as Perl itself.

# VERSION HISTORY

    0.1   - Initial version.
    0.2   - Bugfixes: (a) fix errors on Perl 5.18 and older, (b) address an issue
            with GMPz wrt Math::BigInt objects.
    0.3   - Bugfix: Try to prevent 'Inappropriate argument' error from pre-0.43
            versions of Math::GMPz.
    0.4   - Bugfix: 'Invalid argument supplied to Math::GMPz::overload_mod' for
            older versions of Math::GMPz on Windows and FreeBSD. Podfix.
    1.0.0 - UUID conversion support; semantic versioning.
    1.1.0 - Speedups courtesy of Bartosz Jarzyna (brtastic on CPAN, bbrtj on
            Github). Use Crypt::PRNG for random number generation.
    1.1.1 - Fix module version number.
    1.1.2 - Fix POD (version history).
