package At::Protocol::DID 1.0 {
    use v5.42;
    no warnings qw[experimental::try];
    use feature 'try';
    use At::Error qw[register throw];
    use parent -norequire => 'Exporter';
    use overload
        '""' => sub ( $s, $u, $q ) {
        $$s;
        };
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[ensureValidDid ensureValidDidRegex] ] );

    sub new( $class, $did ) {
        try {
            ensureValidDid($did);
        }
        catch ($err) { return; }
        bless \$did, $class;
    }

    #~ Taken from https://github.com/bluesky-social/atproto/blob/main/packages/syntax/src/did.ts
    #~ Human-readable constraints:
    #~   - valid W3C DID (https://www.w3.org/TR/did-core/#did-syntax)
    #~      - entire URI is ASCII: [a-zA-Z0-9._:%-]
    #~      - always starts "did:" (lower-case)
    #~      - method name is one or more lower-case letters, followed by ":"
    #~      - remaining identifier can have any of the above chars, but can not end in ":"
    #~      - it seems that a bunch of ":" can be included, and don't need spaces between
    #~      - "%" is used only for "percent encoding" and must be followed by two hex characters (and thus can't end in "%")
    #~      - query ("?") and fragment ("#") stuff is defined for "DID URIs", but not as part of identifier itself
    #~      - "The current specification does not take a position on the maximum length of a DID"
    #~   - in current atproto, only allowing did:plc and did:web. But not *forcing* this at lexicon layer
    #~   - hard length limit of 8KBytes
    #~   - not going to validate "percent encoding" here
    sub ensureValidDid ($did) {

        # check that all chars are boring ASCII
        throw InvalidDidError('Disallowed characters in DID (ASCII letters, digits, and a couple other characters only)')
            unless $did =~ /^[a-zA-Z0-9._:%-]*$/;
        #
        my @parts = split ':', $did, -1;    # negative limit, ftw
        throw InvalidDidError('DID requires prefix, method, and method-specific content') if @parts < 3;
        #
        throw InvalidDidError('DID requires "did:" prefix') if $parts[0] ne 'did';
        #
        throw InvalidDidError('DID method must be lower-case letters') if $parts[1] !~ /^[a-z]+$/;
        #
        throw InvalidDidError('DID can not end with ":" or "%"')       if $did =~ /[:%]$/;
        throw InvalidDidError('DID is too long (2048 characters max)') if length $did > 2 * 1024;
        1;
    }

    sub ensureValidDidRegex ($did) {

        #~ simple regex to enforce most constraints via just regex and length.
        #~ hand wrote this regex based on above constraints
        throw InvalidDidError(q[DID didn't validate via regex])        if $did !~ /^did:[a-z]+:[a-zA-Z0-9._:%-]*[a-zA-Z0-9._-]$/;
        throw InvalidDidError('DID is too long (2048 characters max)') if length $did > 2 * 1024;
        #
        1;
    }

    # fatal error
    register 'InvalidDidError', 1;
};
1;
__END__
=encoding utf-8

=head1 NAME

At::Protocol::DID - AT Protocol DID Validation

=head1 SYNOPSIS

    use At::Protocol::DID qw[:all];
    try {
        ensureValidDid( 'did:method:val' );
    }
    catch($err) {
        ...; # do something about it
    }

=head1 DESCRIPTION

The AT Protocol uses L<Decentralized Identifiers|https://en.wikipedia.org/wiki/Decentralized_identifier> (DIDs) as
persistent, long-term account identifiers. DID is a W3C standard, with many standardized and proposed DID method
implementations.

This package aims to validate them.

=head1 Functions

You may import functions by name or with the C<:all> tag.

=head2 C<new( ... )>

Verifies a DID and creates a new object containing it.

    my $handle = At::Protocol::DID->new( 'did:web:blueskyweb.xyz' );

On success, an object is returned that will stringify to the DID itself.

=head2 C<ensureValidDid( ... )>

    ensureValidDid( 'did:plc:z72i7hdynmk6r22z27h6tvur' );

Validates a DID. Throws errors on failure and returns a true value on success.

=head2 C<ensureValidDidRegex( ... )>

    ensureValidDidRegex( 'did:method::nope' );

Validates a DID with cursory regex provided by the AT protocol designers. Throws errors on failure and returns a true
value on success.

=head1 See Also

L<https://atproto.com/specs/did>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

atproto

=end stopwords

=cut
