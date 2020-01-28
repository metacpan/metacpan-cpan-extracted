package CBOR::PP::Decode;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

CBOR::PP::Decode

=head1 SYNOPSIS

    my $perlvar = CBOR::PP::Decode::decode($binary);

=head1 DESCRIPTION

This implements a basic CBOR decoder in pure Perl.

=head1 MAPPING CBOR TO PERL

=over

=item * All tags are ignored. (This could be iterated on later.)

=item * Indefinite-length objects are supported, but streamed parsing
is not; the data structure must be complete to be decoded.

=item * CBOR text strings are decoded to UTF8-flagged strings, while
binary strings are decoded to non-UTF8-flagged strings. In practical
terms, this means that a decoded CBOR binary string will have no code point
above 255, while a decoded CBOR text string can contain any valid Unicode
code point.

=item * null, undefined, true, and false become undef, undef,
Types::Serialiser::true(), and Types::Serialiser::false(), respectively.
(NB: undefined is deserialized as an error object in L<CBOR::XS>,
which doesn’t seem to make sense.)

=back

=head1 TODO

=over

=item * Add tag decode support via callbacks.

=item * Make it faster by removing some of the internal buffer copying.

=back

=head1 AUTHOR

L<Gasper Software Consulting|http://gaspersoftware.com> (FELIPE)

=head1 LICENSE

This code is licensed under the same license as Perl itself.

=cut

#----------------------------------------------------------------------

=head1 METHODS

=head2 $value = decode( $CBOR_BYTESTRING )

Returns a Perl value that represents the serialized CBOR string.

=cut

my ($byte1, $offset, $lead3bits);

my $len;

# This ensures that pieces of indefinite-length strings
# are all of the same type.
our $_lead3_must_be;

use constant {
    _LEAD3_UINT => 0,
    _LEAD3_NEGINT => 1 << 5,
    _LEAD3_BINSTR => 2 << 5,
    _LEAD3_UTF8STR => 3 << 5,
    _LEAD3_ARRAY => 4 << 5,
    _LEAD3_HASH => 5 << 5,
    _LEAD3_TAG => 6 << 5,
};

# CBOR is much simpler to create than it is to parse!

# TODO: Optimize by removing the buffer duplication.

sub decode {
    $offset = 0;

    for ($_[0]) {
        $byte1 = ord( substr( $_, $offset, 1 ) );
        $lead3bits = 0xe0 & $byte1;

        die "Improper lead3 ($lead3bits) within streamed $_lead3_must_be!" if $_lead3_must_be && $lead3bits != $_lead3_must_be;

        #use Text::Control;
        #print Text::Control::to_hex($_) . $/;

        if ($lead3bits == _LEAD3_UINT()) {
            return (1, ord) if $byte1 < 0x18;

            return (2, unpack('x C', $_)) if $byte1 == 0x18;

            return (3, unpack('x n', $_)) if $byte1 == 0x19;

            return (5, unpack('x N', $_)) if $byte1 == 0x1a;

            return (9, unpack('x Q>', $_));
        }

        elsif ($lead3bits == _LEAD3_NEGINT()) {
            return (1, 0x1f - ord()) if $byte1 < 0x38;

            return (2, -unpack( 'x C', $_) - 1) if $byte1 == 0x38;

            return (3, -unpack( 'x n', $_) - 1) if $byte1 == 0x39;

            return (5, -unpack( 'x N', $_) - 1) if $byte1 == 0x3a;

            return (9, -unpack( 'x Q>', $_) - 1);
        }

        elsif ($lead3bits == _LEAD3_BINSTR()) {
            my $hdrlen;

            if ($byte1 < 0x58) {
                $len = $byte1 - 0x40;
                $hdrlen = 1;
            }
            elsif ($byte1 == 0x58) {
                $len = unpack 'x C', $_;
                $hdrlen = 2;
            }
            elsif ($byte1 == 0x59) {
                $len = unpack 'x n', $_;
                $hdrlen = 3;
            }
            elsif ($byte1 == 0x5a) {
                $len = unpack 'x N', $_;
                $hdrlen = 5;
            }
            elsif ($byte1 == 0x5b) {
                $len = unpack 'x Q>', $_;
                $hdrlen = 9;
            }
            elsif ($byte1 == 0x5f) {
                return _stringstream();
            }
            else {
                die "Invalid lead byte: $byte1";
            }

            return ($hdrlen + $len, substr( $_, $hdrlen, $len ));
        }

        elsif ($lead3bits == _LEAD3_UTF8STR()) {
            my $hdrlen;

            if ($byte1 < 0x78) {
                $len = $byte1 - 0x60;
                $hdrlen = 1;
            }
            elsif ($byte1 == 0x78) {
                $len = unpack 'x C', $_;
                $hdrlen = 2;
            }
            elsif ($byte1 == 0x79) {
                $len = unpack 'x n', $_;
                $hdrlen = 3;
            }
            elsif ($byte1 == 0x7a) {
                $len = unpack 'x N', $_;
                $hdrlen = 5;
            }
            elsif ($byte1 == 0x7b) {
                $len = unpack 'x Q>', $_;
                $hdrlen = 9;
            }
            elsif ($byte1 == 0x7f) {
                return _stringstream();
            }
            else {
                die "Invalid lead byte: $byte1";
            }

            my $v = substr( $_, $hdrlen, $len );
            utf8::decode($v);

            # A no-op if $v is already UTF8-flagged, but if it’s not,
            # then this will apply the flag. We thus preserve the ability
            # to round-trip a character string through Perl.
            utf8::upgrade($v);

            return ($hdrlen + $len, $v);
        }

        elsif ($lead3bits == _LEAD3_ARRAY()) {
            my $total;

            if ($byte1 < 0x98) {
                $len = $byte1 - 0x80;
                $total = 1;
            }
            elsif ($byte1 == 0x98) {
                $len = unpack 'x C', $_;
                $total = 2;
            }
            elsif ($byte1 == 0x99) {
                $len = unpack 'x n', $_;
                $total = 3;
            }
            elsif ($byte1 == 0x9a) {
                $len = unpack 'x N', $_;
                $total = 5;
            }
            elsif ($byte1 == 0x9b) {
                $len = unpack 'x Q>', $_;
                $total = 9;
            }
            elsif ($byte1 == 0x9f) {
                return _arraystream();
            }
            else {
                die "Invalid lead byte: $byte1";
            }

            # pre-fill the array
            my @val = (undef) x $len;

            my $cur_len;

            for my $i ( 0 .. ($len - 1) ) {
                ($cur_len, $val[$i]) = decode( substr( $_, $total ) );
                $total += $cur_len;
            }

            return( $total, \@val );
        }

        elsif ($lead3bits == _LEAD3_HASH()) {
            my ($len, $total);

            if ($byte1 < 0xb8) {
                $len = $byte1 - 0xa0;
                $total = 1;
            }
            elsif ($byte1 == 0xb8) {
                $len = unpack 'x C', $_;
                $total = 2;
            }
            elsif ($byte1 == 0xb9) {
                $len = unpack 'x n', $_;
                $total = 3;
            }
            elsif ($byte1 == 0xba) {
                $len = unpack 'x N', $_;
                $total = 5;
            }
            elsif ($byte1 == 0xbb) {
                $len = unpack 'x Q>', $_;
                $total = 9;
            }
            elsif ($byte1 == 0xbf) {
                return _hashstream();
            }
            else {
                die "Invalid lead byte: $byte1";
            }

            my %val;

            my $cur_len;

            while ( $len > 0 ) {
                ($cur_len, my $key) = decode( substr( $_, $total ) );
                $total += $cur_len;

                ( $cur_len, $val{$key} ) = decode( substr( $_, $total ) );
                $total += $cur_len;

                $len--;
            }

            return( $total, \%val );
        }

        # tags … just ignore for now
        elsif ($lead3bits == _LEAD3_TAG()) {
            my $taglen;

            if ($byte1 < 0xd8) {
                $taglen = 1;
            }
            elsif ($byte1 == 0xd8) {
                $taglen = 2;
            }
            elsif ($byte1 == 0xd9) {
                $taglen = 3;
            }
            elsif ($byte1 == 0xda) {
                $taglen = 5;
            }
            elsif ($byte1 == 0xdb) {
                $taglen = 9;
            }
            else {
                die "Invalid lead byte: $byte1";
            }

            my @ret = decode( substr( $_, $taglen ) );
            return( $taglen + $ret[0], $ret[1] );
        }

        # floats, true, false, null, undefined
        else {
            if ($byte1 == 0xf4) {
                require Types::Serialiser;
                return ( 1, Types::Serialiser::false() );
            }
            elsif ($byte1 == 0xf5) {
                require Types::Serialiser;
                return ( 1, Types::Serialiser::true() );
            }
            elsif ($byte1 == 0xf6 || $byte1 == 0xf7) {
                return (1, undef);
            }
            elsif ($byte1 == 0xf9) {

                # Adapted from the Python code in RFC 7049 appendix D:
                my $half = unpack 'x n', $_;
                my $valu = (($half & 0x7fff) << 13) | (($half & 0x8000) << 16);

                if (($half & 0x7c00) != 0x7c00) {
                    return( unpack('f>', pack('N', $valu)) * (2**112) );
                }

                return ( 3, unpack('f>', pack('N', $valu | 0x7f800000)) );
            }
            elsif ($byte1 == 0xfa) {
                return ( 5, unpack( 'x f>', $_ ) );
            }
            elsif ($byte1 == 0xfb) {
                return ( 5, unpack( 'x d>', $_ ) );
            }

            die sprintf('can’t decode special value: %v.02x', $_);
        }
    }
}

sub _stringstream {
    my $full = q<>;

    my $i = 1;

    local $_lead3_must_be = $lead3bits;

    while (1) {
        die 'Incomplete indefinite-length string!' if $i >= length();

        if ("\xff" eq substr( $_, $i, 1 )) {
            $i++;
            last;
        }

        my ($len, $chunk) = decode( substr( $_, $i ) );

        $full .= $chunk;
        $i += $len;
    }

    utf8::decode($full) if $lead3bits == _LEAD3_UTF8STR();

    return ($i, $full);
}

sub _arraystream {
    my @full;

    my $i = 1;

    while (1) {
        die 'Incomplete indefinite-length array!' if $i >= length();

        if ("\xff" eq substr( $_, $i, 1 )) {
            $i++;
            last;
        }

        my ($len, $chunk) = decode( substr( $_, $i ) );

        push @full, $chunk;
        $i += $len;
    }

    return ($i, \@full);
}

sub _hashstream {
    my %full;

    my $i = 1;

    while (1) {
        die 'Incomplete indefinite-length map!' if $i >= length();

        if ("\xff" eq substr( $_, $i, 1 )) {
            $i++;
            last;
        }

        my ($len, $key) = decode( substr( $_, $i ) );
        $i += $len;

        if ( "\xff" eq substr( $_, $i, 1 ) ) {
            die "Odd number of elements in map! (Last key: “$key”)";
        }

        ($len, $full{$key}) = decode( substr( $_, $i ) );
        $i += $len;
    }

    return ($i, \%full);
}

1;
