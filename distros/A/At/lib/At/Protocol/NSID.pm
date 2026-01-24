package At::Protocol::NSID 1.0 {    # https://github.com/bluesky-social/atproto/blob/main/packages/syntax/src/nsid.ts
    use v5.42;
    no warnings qw[experimental::builtin experimental::try];
    use At::Error qw[register throw];
    use feature 'try';
    use parent -norequire => 'Exporter';
    use overload
        '""' => sub ( $s, $u, $q ) {
        join '.', @$s;
        };
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[parse create isValid ensureValidNsid ensureValidNsidRegex] ] );

#~ Grammar:
#~  alpha     = "a" / "b" / "c" / "d" / "e" / "f" / "g" / "h" / "i" / "j" / "k" / "l" / "m" / "n" / "o" / "p" / "q" / "r" / "s" / "t" / "u" / "v" / "w" / "x" / "y" / "z" / "A" / "B" / "C" / "D" / "E" / "F" / "G" / "H" / "I" / "J" / "K" / "L" / "M" / "N" / "O" / "P" / "Q" / "R" / "S" / "T" / "U" / "V" / "W" / "X" / "Y" / "Z"
#~  number    = "1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9" / "0"
#~  delim     = "."
#~  segment   = alpha *( alpha / number / "-" )
#~  authority = segment *( delim segment )
#~  name      = alpha *( alpha / number )
#~  nsid      = authority delim name
    sub new( $class, $nsid ) {
        ensureValidNsid($nsid);
        bless [ split /\./, $nsid, -1 ], $class;
    }

    sub parse($nsid) {
        __PACKAGE__->new($nsid);
    }

    sub create( $authority, $name ) {
        parse join '.', reverse( split( /\./, $authority, -1 ) ), $name;
    }
    sub authority($s) { join '.', reverse splice( @$s, 0, -1 ); }

    sub name($s) {
        @$s[-1];
    }

    sub isValid($nsid) {
        try {
            parse($nsid);
            return 1;
        }
        catch ($err) { return 0; }
    }

    #~ Human readable constraints on NSID:
    #~  - a valid domain in reversed notation
    #~  - followed by an additional period-separated name, which is camel-case letters
    sub ensureValidNsid($nsid) {

        # check that all chars are boring ASCII
        throw InvalidNsidError('Disallowed characters in NSID (ASCII letters, digits, dashes, periods only)') unless $nsid =~ /^[a-zA-Z0-9.-]*$/;
        #
        throw InvalidNsidError('NSID is too long (317 chars max)') if length $nsid > 253 + 1 + 63;
        my @labels = split /\./, $nsid, -1;    # negative length, ftw

        #
        throw InvalidNsidError('NSID needs at least three parts') if scalar @labels < 3;
        #
        for my $i ( 0 .. $#labels ) {
            my $l = $labels[$i];
            throw InvalidNsidError('NSID parts can not be empty') unless length $l;
            throw InvalidNsidError('NSID part too long (max 63 chars)')           if length $l > 63;
            throw InvalidNsidError('NSID parts can not start or end with hyphen') if $l =~ /^-|-$/;
            throw InvalidNsidError('NSID first part may not start with a digit')  if $i == 0        && $l =~ /^[0-9]/;
            throw InvalidNsidError('NSID name part must be letters or digits')    if $i == $#labels && $l !~ /^[a-zA-Z][a-zA-Z0-9]*$/;
        }
        1;
    }

    sub ensureValidNsidRegex ($nsid) {

        #~ simple regex to enforce most constraints via just regex and length.
        #~ hand wrote this regex based on above constraints
        throw InvalidNsidError(q[NSID didn't validate via regex])
            unless $nsid =~ /^[a-zA-Z]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+(\.[a-zA-Z][a-zA-Z0-9]{0,62})$/;
        throw InvalidNsidError('NSID is too long (317 chars max)') if length $nsid > 253 + 1 + 63;
        1;
    }
    #
    register 'InvalidNsidError', 1;
};
1;
__END__
=pod

=encoding utf-8

=head1 NAME

At::Protocol::NSID - AT Protocol NSID Validation

=head1 SYNOPSIS

    use At::Protocol::NSID qw[:all];
    try {
        ensureValidNSID( 'net.users.bob.ping' );
    }
    catch($err) {
        ...; # do something about it
    }

=head1 DESCRIPTION

Namespaced Identifiers (NSIDs) are used to reference Lexicon schemas for records, XRPC endpoints, and more.

The basic structure and semantics of an NSID are a fully-qualified hostname in Reverse Domain-Name Order, followed by a
simple name. The hostname part is the B<domain authority>, and the final segment is the B<name>.

This package aims to validate them.

=head1 Functions

You may import functions by name or with the C<:all> tag.

=head2 C<new( ... )>

Verifies an NSID and creates a new object containing it.

    my $nsid = At::Protocol::NSID->new( 'com.example.fooBar' );

On success, an object is returned that will stringify to the NSID itself.

=head2 C<parse( ... )>

    my $nsid = parse( 'com.example.fooBar' );

Wrapper around C<new(...)> for the sake of compatibility.

=head2 C<create( ... )>

    my $nsid = create( 'alex.example.com' );

Parses a 'normal' (sub)domain name and creates an NSID object.

=head2 C<authority( )>

    my $auth = $nsid->authority;

Returns the domain authority of the NSID.

=head2 C<name( )>

    my $name = $nsid->name;

Returns the name from the NSID.

=head2 C<isValid( ... )>

    my $ok = isValid( 'com.exa💩ple.thing' );

Returns a boolean value indicating whether the given NSID is valid and can be parsed.

=head2 C<ensureValidNsid( ... )>

    ensureValidNsid( '.com.example.wrong' );

Validates an NSID. Throws errors on failure and returns a true value on success.

=head2 C<ensureValidNsidRegex( ... )>

    ensureValidNsidRegex( 'com.example.right' );

Validates an NSID with cursory regex provided by the AT protocol designers. Throws errors on failure and returns a true
value on success.

=head1 See Also

L<https://atproto.com/specs/nsid>

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
