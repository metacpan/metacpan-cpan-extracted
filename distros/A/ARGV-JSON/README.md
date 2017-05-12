# NAME

ARGV::JSON - Parses @ARGV for accessing JSON via `<>`

# SYNOPSIS

    use ARGV::JSON;

    while (<>) {
        # $_ is a decoded JSON here!
    }

Or in one-liner:

    perl -MARGV::JSON -anal -E 'say $_->{foo}->{bar}' a.json b.json

# DESCRIPTION

ARGV::JSON parses each input from `@ARGV` and enables to access
the JSON data structures via `<>`.

Each `readline` call to `<>` (or `<ARGV>`) returns a
hashref or arrayref or something that the input serializes in the
JSON format.

# SEE ALSO

[ARGV::URL](https://metacpan.org/pod/ARGV::URL).

# LICENSE

Copyright (C) motemen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

motemen <motemen@gmail.com>
