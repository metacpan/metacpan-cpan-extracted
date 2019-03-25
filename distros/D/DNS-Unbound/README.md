# NAME

DNS::Unbound - A Perl interface to NLNetLabs’s [Unbound](https://nlnetlabs.nl/projects/unbound/) recursive DNS resolver

# SYNOPSIS

    my $dns = DNS::Unbound->new()->set_option( verbosity => 2 );

    my $verbosity = $dns->get_option( 'verbosity' );

    $dns->set_option( verbosity => 1 + $verbosity );

    my $res_hr = $dns->resolve( 'cpan.org', 'NS' );

    # See below about encodings in “data”.
    my @ns = map { $dns->decode_name($_) } @{ $res_hr->{'data'} };

# METHODS

## _CLASS_->new()

Instantiates this class.

## $result\_hr = _OBJ_->resolve( $NAME, $TYPE \[, $CLASS \] )

Runs a synchronous query for a given $NAME and $TYPE. $TYPE may be
expressed numerically or, for convenience, as a string. $CLASS is
optional and defaults to 1 (`IN`), which is probably what you want.

Returns a reference to a hash that corresponds
to a libunbound `struct ub_result`
(cf. [libunbound(3)](https://nlnetlabs.nl/documentation/unbound/libunbound/)),
excluding `len`, `answer_packet`, and `answer_len`.

**NOTE:** Members of `data` are in their DNS-native RDATA encodings.
(libunbound doesn’t track which record type uses which encoding, so
neither does DNS::Unbound.)
To decode some common record types, see ["CONVENIENCE FUNCTIONS"](#convenience-functions) below.

## _OBJ_->set\_option( $NAME => $VALUE )

Sets a configuration option. Returns _OBJ_.

## $value = _OBJ_->get\_option( $NAME )

Gets a configuration option’s value.

## _CLASS_->unbound\_version()

Gives the libunbound version string.

# CONVENIENCE FUNCTIONS

Note that [Socket](https://metacpan.org/pod/Socket) provides the `inet_ntoa()` and `inet_ntop()`
functions for decoding `A` and `AAAA` records.

The following may be called either as object methods or as static
functions (but not as class methods):

## $decoded = decode\_name($encoded)

Decodes a DNS name. Useful for, e.g., `NS` query results.

Note that this will normally include a trailing `.` because of the
trailing NUL byte in an encoded DNS name.

## $strings\_ar = decode\_character\_strings($encoded)

Decodes a list of character-strings into component strings,
returned as an array reference. Useful for `TXT` query results.

# REPOSITORY

[https://github.com/FGasper/p5-DNS-Unbound](https://github.com/FGasper/p5-DNS-Unbound)

# THANK YOU

Special thanks to [ATOOMIC](https://metacpan.org/author/ATOOMIC) for
making some helpful review notes.
