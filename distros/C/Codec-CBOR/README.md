# NAME

Codec::CBOR - DAG-CBOR encoder and decoder

# SYNOPSIS

```perl
use Codec::CBOR;

my $codec = Codec::CBOR->new();

# Encode data to CBOR bytes
my $bytes = $codec->encode({
    t    => '#commit',
    repo => 'did:plc:123',
    data => { key => 'value' }
});

# Decode CBOR bytes back to Perl data
my $data = $codec->decode($bytes);

# Decode a sequence of concatenated CBOR objects
my @objects = $codec->decode_sequence($concatenated_bytes);
```

# DESCRIPTION

Codec::CBOR is a thin, pure Perl implementation of the Concise Binary Object Representation (CBOR) format, specifically
optimized for DAG-CBOR as used in the [AT](https://metacpan.org/pod/At) Protocol and [IPFS](https://metacpan.org/pod/Interplanetary).

## DAG-CBOR Compliance

This module implements the following DAG-CBOR requirements:

- Deterministic map encoding: Map keys are sorted by length (shorter first), then lexically.
- Tag 42 support: Special handling for Content Identifiers (CIDs).
- No indefinite lengths: Only definite length arrays and maps are supported.

# METHODS

## `new()`

Constructor. Returns a new `Codec::CBOR` instance.

## `encode($data)`

Encodes a Perl data structure into a CBOR byte string.

- Strings: Encoded as Major Type 3 (UTF-8) if they are not references.
- Byte strings: Encoded as Major Type 2 if provided as a scalar reference (e.g., `\$binary_data`).
- Tags: Registered class handlers can produce tagged values (Major Type 6).

## `decode($input)`

Decodes a single CBOR object from a byte string or a filehandle. Returns the decoded Perl data structure.

## `decode_sequence($input)`

Decodes a sequence of concatenated CBOR objects. Returns an array (in list context) or an arrayref.

## `add_tag_handler($tag, $callback)`

Registers a callback to handle a specific CBOR tag during decoding.

```perl
$codec->add_tag_handler(42 => sub ($data) {
    return My::CID->from_raw($data);
});
```

## `add_class_handler($class, $callback)`

Registers a callback to handle a specific Perl class during encoding.

```perl
$codec->add_class_handler('My::CID' => sub ($codec, $obj) {
    return $codec->_encode_tag(42, $obj->raw);
});
```

# SEE ALSO

[Archive::CAR](https://metacpan.org/pod/Archive%3A%3ACAR), [At](https://metacpan.org/pod/At), [https://cbor.io/](https://cbor.io/), [https://ipld.io/specs/codecs/dag-cbor/](https://ipld.io/specs/codecs/dag-cbor/), [CBOR::Free](https://metacpan.org/pod/CBOR%3A%3AFree)

# AUTHOR

Sanko Robinson <sanko@cpan.org>

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.
