# NAME

Archive::CAR - Content Addressable Archive (CAR) reader and writer

# SYNOPSIS

```perl
use Archive::CAR;

# Load a CAR file
my $car = Archive::CAR->from_file('data.car');

say 'CAR Version: ' . $car->version;

# Access roots
for my $root ($car->roots->@*) {
    # $root is an Archive::CAR::CID object
    say 'Root CID: ' . $root->to_string;
}

# Access blocks
for my $block ($car->blocks->@*) {
    my $cid = $block->{cid};
    my $data = $block->{data};
    say 'Block ' . $cid->to_string . ' is ' . length($data) . ' bytes';
}
```

# DESCRIPTION

Archive::CAR provides support for the Content Addressable Archive format used by IPFS. A CAR file is a serialized
stream of IPLD blocks (CID + data) concatenated together, usually starting with a header that identifies the "roots" of
the data DAG (Directed Acyclic Graph).

This module supports both CAR v1 (simple concatenation) and CAR v2 which adds an index for fast random access.

# METHODS

## `from_file($path)`

Constructs an Archive::CAR object by parsing the file at the given path. Detects version automatically.

## `write($filename, $roots, $blocks, [ $version ])`

Writes a new CAR file. `$roots` is an arrayref of CIDs, and `$blocks` is an arrayref of hashes containing `cid` and
`data`. `$version` defaults to 1.

## `version()`

Returns the version of the CAR file (1 or 2).

## `roots()`

Returns an array reference of [Archive::CAR::CID](https://metacpan.org/pod/Archive%3A%3ACAR%3A%3ACID) objects that are the designated entry points for this archive.

## `blocks()`

Returns an array reference of hashes, where each hash contains `cid` (an [Archive::CAR::CID](https://metacpan.org/pod/Archive%3A%3ACAR%3A%3ACID) object) and `data` (the
raw binary block).

# SEE ALSO

[https://ipld.io/specs/transport/car/](https://ipld.io/specs/transport/car/), [Archive::CAR::CID](https://metacpan.org/pod/Archive%3A%3ACAR%3A%3ACID), [Archive::CAR::v1](https://metacpan.org/pod/Archive%3A%3ACAR%3A%3Av1), [Archive::CAR::v2](https://metacpan.org/pod/Archive%3A%3ACAR%3A%3Av2)

# AUTHOR

Sanko Robinson <sanko@cpan.org>

# COPYRIGHT

Copyright (C) 2026 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
