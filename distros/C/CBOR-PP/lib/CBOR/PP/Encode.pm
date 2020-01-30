package CBOR::PP::Encode;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

CBOR::PP::Decode

=head1 SYNOPSIS

    my $perlvar = CBOR::PP::Decode::decode($binary);

=head1 DESCRIPTION

This implements a L<CBOR|https://tools.ietf.org/html/rfc7049> encoder
in pure Perl.

=head1 MAPPING PERL TO CBOR

=over

=item * Scalars that look like unsigned integers are encoded as such.
UTF-8 strings and strings that fit 7-bit ASCII (including floats and
negatives) are encoded as text. Any other scalar is encoded as binary.

Note that there is no “right way” to determine whether an arbitrary
Perl (non-reference) scalar should be encoded as a string or as a number.
The above seems a reasonable enough approach.

=item * UTF8-flagged strings are encoded as text; others are encoded as
binary. This is a “best-guess” merely; Perl’s UTF8 flag doesn’t reliably
indicate whether a given string is a text or a byte string.

=item * undef, Types::Serialiser::true(), and Types::Serialiser::false()
are encoded as null, true, and false, respectively.

=item * There is no support for streamed (i.e., indefinite-length)
objects.

=item * There is no Perl value that maps to CBOR’s undefined value.

=back

=head1 TODO

=over

=item * Add canonicalization support.

=item * Optimize as may be feasible.

=back

=head1 AUTHOR

L<Gasper Software Consulting|http://gaspersoftware.com> (FELIPE)

=head1 LICENSE

This code is licensed under the same license as Perl itself.

=cut

#----------------------------------------------------------------------

use CBOR::PP::X;
use CBOR::PP::Tagged;

#----------------------------------------------------------------------

=head1 FUNCTIONS

=head2 $obj = tag( $NUMBER, $VALUE )

Returns an object that represents a value and its CBOR tag number.
For example, to encode a date/time string, you could do:

    my $tagged = tag(0, '2013-03-21T20:04:00Z')

C<encode()> recognizes objects that this function returns and
turns them into tagged CBOR values.

=cut

sub tag {
    return CBOR::PP::Tagged->new(@_);
}

#----------------------------------------------------------------------

=head1 METHODS

=head2 $cbor = encode( $VALUE, \%OPTS )

Returns a CBOR string that represents the passed $VALUE.

For now this is only called as a static method but may eventually
be an instance method as well, for example, to define options like
canonicalization.

=cut

my ($numkeys);

our $_depth = 0;

# Avoid tripping Perl’s warning:
use constant _MAX_RECURSION => 98;

sub encode {

    # There’s a lot of ugliness in here for the sake of speed.
    # For example, ideally each major type would have its own function,
    # but we realize significant savings by putting everything into
    # one big function.

    local $_depth = $_depth + 1;
    die CBOR::PP::X->create('Recursion', sprintf("Refuse to encode() more than %d times at once!", _MAX_RECURSION())) if $_depth > _MAX_RECURSION();

    for ($_[0]) {
        if (!ref) {

            # undef => null
            return "\xf6" if !defined;

            # empty string
            return utf8::is_utf8($_) ? "\x60" : "\x40" if !length;

            # unsigned int
            if (!$_ || (!tr<0-9><>c && 0 != rindex($_, 0, 0))) {
                return chr $_ if ($_ < 24);

                return pack('CC', 0x18, $_) if $_ < 0x100;

                return pack('Cn', 0x19, $_) if ($_ < 0x10000);

                return pack('CN', 0x1a, $_) if ($_ <= 0xffffffff);

                return pack('C Q>', 0x1b, $_);
            }

            # negative int
            #    elsif ( 0 == rindex($_, '-', 0) && (substr($_, 1) !~ tr<0-9><>c) ) {
            #        return chr( 0x20 - $_ ) if ($_ > -25);
            #
            #        return pack( 'CC', 0x38, -$_ ) if $_ >= -0x100;
            #
            #        return pack( 'Cv', 0x39, -$_ ) if $_ >= -0x10000;
            #
            #        return pack( 'CV', 0x3a, -$_ ) if $_ >= -0x100000000;
            #
            #        return pack( 'C Q>', 0x3b, -$_ );
            #    }

            if (utf8::is_utf8($_)) {

                # We need our string to be in UTF-8.
                utf8::encode(my $bytes = $_);

                return pack('Ca*', 0x60 + length($bytes), $bytes) if (length() < 24);

                return pack('CCa*', 0x78, length($bytes), $bytes) if (length() < 0x100);

                return pack('Cna*', 0x79, length($bytes), $bytes) if (length() < 0x10000);

                return pack('CNa*', 0x7a, length($bytes), $bytes) if (length() <= 0xffffffff);

                return pack('C Q> a*', 0x7b, length($bytes), $bytes);
            }
            else {
                return pack('Ca*', 0x40 + length, $_) if (length() < 24);

                return pack('CCa*', 0x58, length, $_) if (length() < 0x100);

                return pack('Cna*', 0x59, length, $_) if (length() < 0x10000);

                return pack('CNa*', 0x5a, length, $_) if (length() <= 0xffffffff);

                return pack('C Q> a*', 0x5b, length, $_);
            }
        }
        elsif (ref eq 'ARRAY') {
            my $hdr;

            if (@$_ < 24) {
                $hdr = chr( 0x80 + @$_ );
            }
            elsif (@$_ < 0x100) {
                $hdr = pack( 'CC', 0x98, 0 + @$_ );
            }
            elsif (@$_ < 0x10000) {
                $hdr = pack( 'Cn', 0x99, 0 + @$_ );
            }
            elsif (@$_ <= 0xffffffff) {
                $hdr = pack( 'CN', 0x9a, 0 + @$_ );
            }
            else  {
                $hdr = pack( 'C Q>', 0x9b, 0 + @$_ );
            }

            return join( q<>, $hdr, map { encode($_, $_[1]) } @$_ );
        }
        elsif (ref eq 'HASH') {
            my $hdr;

            $numkeys = keys %$_;

            if ($numkeys < 24) {
                $hdr = chr( 0xa0 + $numkeys );
            }
            elsif ($numkeys < 0x100) {
                $hdr = pack( 'CC', 0xb8, $numkeys );
            }
            elsif ($numkeys < 0x10000) {
                $hdr = pack( 'Cn', 0xb9, $numkeys );
            }
            elsif ($numkeys <= 0xffffffff) {
                $hdr = pack( 'CN', 0xba, $numkeys );
            }
            else  {
                $hdr = pack( 'C Q>', 0xbb, $numkeys );
            }

            if ($_[1] && $_[1]->{'canonical'}) {
                my $hr = $_;

                my @keys = sort { (length($a) <=> length($b)) || ($a cmp $b) } keys %$_;
                return join( q<>, $hdr, map { encode($_), encode($hr->{$_}, $_[1]) } @keys );
            }
            else {
                return join( q<>, $hdr, map { encode($_, $_[1]) } %$_ );
            }
        }
        elsif (ref()->isa('JSON::PP::Boolean')) {
            return $_ ? "\xf5" : "\xf4";
        }
        elsif (ref()->isa('CBOR::PP::Tagged')) {
            my $numstr = encode( $_->[0] );

            substr($numstr, 0, 1) &= "\x1f";     # zero out the first three bits
            substr($numstr, 0, 1) |= "\xc0";     # now assign the first three

            return( $numstr . encode( $_->[1], $_[1] ) );
        }

        die "Can’t encode “$_” as CBOR!";
    }
}

1;
