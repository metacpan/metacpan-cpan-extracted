package At::Protocol::Handle 1.0 {
    use v5.38;
    use At::Error qw[register throw];
    use parent -norequire => 'Exporter';
    use feature 'try';
    no warnings qw[experimental::try];
    use overload
        '""' => sub ( $s, $u, $q ) {
        $$s;
        };
    our %EXPORT_TAGS = (
        all => [
            our @EXPORT_OK
                = qw[
                ensureValidHandle ensureValidHandleRegex
                normalizeHandle normalizeAndEnsureValidHandle
                isValidHandle isValidTld]
        ]
    );
    #
    my $INVALID_HANDLE = 'handle.invalid';

    #~ Currently these are registration-time restrictions, not protocol-level
    #~ restrictions. We have a couple accounts in the wild that we need to clean up
    #~ before hard-disallow.
    #~ See also: https://en.wikipedia.org/wiki/Top-level_domain#Reserved_domains
    my @DISALLOWED_TLDS = (
        '.local', '.arpa', '.invalid', '.localhost', '.internal', '.example', '.alt',

        # policy could concievably change on ".onion" some day
        '.onion',

        #~ NOTE: .test is allowed in testing and devopment. In practical terms
        #~ "should" "never" actually resolve and get registered in production
    );

    sub new( $class, $id ) {
        throw UnsupportedDomainError('invalid TLD') unless isValidTld($id);
        ensureValidHandle($id);
        ensureValidHandleRegex($id);
        CORE::state $warned //= 0;
        if ( $id =~ /\.(test)$/ && !$warned ) {
            require Carp;
            Carp::carp 'development or testing TLD used in handle: ' . $id;
            $warned = 1;
        }
        bless \$id, $class;
    }

    # Taken from https://github.com/bluesky-social/atproto/blob/main/packages/syntax/src/handle.ts
    # Handle constraints, in English:
    #  - must be a possible domain name
    #    - RFC-1035 is commonly referenced, but has been updated. eg, RFC-3696,
    #      section 2. and RFC-3986, section 3. can now have leading numbers (eg,
    #      4chan.org)
    #    - "labels" (sub-names) are made of ASCII letters, digits, hyphens
    #    - can not start or end with a hyphen
    #    - TLD (last component) should not start with a digit
    #    - can't end with a hyphen (can end with digit)
    #    - each segment must be between 1 and 63 characters (not including any periods)
    #    - overall length can't be more than 253 characters
    #    - separated by (ASCII) periods; does not start or end with period
    #    - case insensitive
    #    - domains (handles) are equal if they are the same lower-case
    #    - punycode allowed for internationalization
    #  - no whitespace, null bytes, joining chars, etc
    #  - does not validate whether domain or TLD exists, or is a reserved or
    #    special TLD (eg, .onion or .local)
    #  - does not validate punycode
    sub ensureValidHandle ($handle) {

        # check that all chars are boring ASCII
        throw InvalidHandleError('Disallowed characters in handle (ASCII letters, digits, dashes, periods only)') if $handle !~ /^[a-zA-Z0-9.-]*$/;
        #
        throw InvalidHandleError('Handle is too long (253 chars max)') if length $handle > 253;
        #
        my @labels = split /\./, $handle, -1;    # negative limit, ftw
        throw InvalidHandleError('Handle domain needs at least two parts') if scalar @labels < 2;
        for my $i ( 0 .. $#labels ) {
            my $l = $labels[$i];
            throw InvalidHandleError('Handle parts can not be empty')                             if !length $l;
            throw InvalidHandleError('Handle part too long (max 63 chars)')                       if length $l > 63;
            throw InvalidHandleError('Handle parts can not start or end with hyphens')            if $l                   =~ /^-|-$/;
            throw InvalidHandleError('Handle final component (TLD) must start with ASCII letter') if $i == $#labels && $l !~ /^[a-zA-Z]/;
        }
        1;
    }

    sub ensureValidHandleRegex ($handle) {
        throw InvalidHandleError(q[Handle didn't validate via regex])
            unless $handle =~ /^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$/;
        throw InvalidHandleError('Handle is too long (253 chars max)') if length $handle > 253;
        1;
    }

    sub normalizeHandle ($handle) {
        lc $handle;
    }

    sub normalizeAndEnsureValidHandle($handle) {
        my $normalized = normalizeHandle($handle);
        ensureValidHandle($normalized);
        $normalized;
    }

    sub isValidHandle ($handle) {
        try {
            ensureValidHandle($handle)
        }
        catch ($err) {    # TODO: I want this to work by checking the type of thrown error but this is perl...
            if ( $err =~ /Handle/ ) {
                return 0;
            }
            die $err;
        }
        1;
    }

    sub isValidTld($handle) {
        for my $tld (@DISALLOWED_TLDS) {
            return 0 if $handle =~ /${tld}$/;
        }
        1;
    }

    # All fatal errors
    register 'InvalidHandleError',     (), 1;
    register 'ReservedHandleError',    (), 1;
    register 'UnsupportedDomainError', (), 1;
    register 'DisallowedDomainError',  (), 1;
};
1;
__END__
=encoding utf-8

=head1 NAME

At::Protocol::Handle - AT Protocol Handle Validation

=head1 SYNOPSIS

    use At::Protocol::Handle qw[:all];
    try {
        ensureValidHandle( 'org.cpan.sanko' );
    }
    catch($err) {
        ...; # do something about it
    }


=head1 DESCRIPTION

L<DID|At::Protocol::DID>s are the long-term persistent identifiers for accounts in atproto, but they can be opaque and
unfriendly for human use. Handles are a less-permanent identifier for accounts. The mechanism for verifying the link
between an account handle and an account DID relies on DNS, and possibly connections to a network host, so every handle
must be a valid network hostname. I<Almost> every valid "hostname" is also a valid handle, though there are a small
number of exceptions.

This package aims to validate them.

=head1 Functions

You may import functions by name or with the C<:all> tag.

=head2 C<new( ... )>

Verifies an id and creates a new object containing it.

    my $handle = At::Protocol::Handle->new( 'org.cpan.sanko' );

On success, an object is returned that will stringify to the id itself.

=head2 C<ensureValidHandle( ... )>

    ensureValidHandle( 'org.cpan.sanko' );

Validates an id. Throws errors on failure and returns a true value on success.

=head2 C<ensureValidHandleRegex( ... )>

    ensureValidHandleRegex( 'org.cpan.sanko' );

Validates an id with cursory regex provided by the AT protocol designers. Throws errors on failure and returns a true
value on success.

=head2 C<normalizeHandle( ... )>

    my $handle = ensureValidHandleRegex( 'org.cpan.SANKO' );

Normalizes a handle according to spec. ...honestly, it just makes sure it's lowercase.

=head2 C<normalizeAndEnsureValidHandle( ... )>

    my $handle = normalizeAndEnsureValidHandle( 'org.cpan.SANKO' );

Normalizes and validates an id. Throws errors on failure and returns the normalized id on success.

=head2 C<isValidHandle( ... )>

    my $ok = ensureValidHandle( 'org.cpan.sanko' );

Validates an id and catches any fatal errors. Returns a boolean value.

=head2 C<isValidTld( ... )>

    my $ok = isValidTld( 'cpan.org' );

Returns a boolean indicating whether the given TLD is valid for use as a handle according to the AT protocol spec.

=head1 See Also

L<https://atproto.com/specs/handle>

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
