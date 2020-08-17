use 5.010001;
use strict;
use warnings;

package BSON::Decimal128;
# ABSTRACT: BSON type wrapper for Decimal128

use version;
our $VERSION = 'v1.12.2';

use Carp;
use Math::BigInt;

use Moo;

#pod =attr value
#pod
#pod The Decimal128 value represented as string.  If not provided, it will be
#pod generated from the C<bytes> attribute on demand.
#pod
#pod =cut

has 'value' => (
    is => 'lazy',
);

#pod =attr bytes
#pod
#pod The Decimal128 value represented in L<Binary Integer
#pod Decimal|https://en.wikipedia.org/wiki/Binary_Integer_Decimal> (BID) format.
#pod If not provided, it will be generated from the C<value> attribute on
#pod demand.
#pod
#pod =cut

has 'bytes' => (
    is => 'lazy',
);

use namespace::clean -except => 'meta';

use constant {
    PLIM  => 34,    # precision limit, i.e. max coefficient chars
    EMAX  => 6144,  # for 9.999999999999999999999999999999999E+6144
    EMIN  => -6143, # for 1.000000000000000000000000000000000E-6143
    AEMAX => 6111,  # EMAX - (PLIM - 1); largest encodable exponent
    AEMIN => -6176, # EMIN - (PLIM - 1); smallest encodable exponent
    BIAS  => 6176,  # offset for encoding exponents
};

my $digits     = qr/[0-9]+/;
my $decimal_re = qr{
    ( [-+]? )                                        # maybe a sign
    ( (?:$digits \. $digits? ) | (?: \.? $digits ) ) # decimal-part
    ( (?:e [-+]? $digits)? )                         # maybe exponent
}ix;

sub _build_value {
    return _bid_to_string( $_[0]->{bytes} );
}

sub _build_bytes {
    return _string_to_bid( $_[0]->{value} );
}

sub BUILD {
    my $self = shift;

    croak "One and only one of 'value' or 'bytes' must be provided"
        unless 1 == grep { exists $self->{$_} } qw/value bytes/;

    # must check for errors and canonicalize value if provided
    if (exists $self->{value}) {
        $self->{value} = _bid_to_string( $self->bytes );
    }

    return;
}

sub _bid_to_string {
    my $bid = shift;
    my $binary = unpack( "B*", scalar reverse($bid) );
    my ( $coef, $e );

    # sign bit
    my $pos = !substr( $binary, 0, 1 );

    # detect special values from first 5 bits after sign bit
    my $special = substr( $binary, 1, 5 );
    if ( $special eq "11111" ) {
        return "NaN";
    }
    if ( $special eq "11110" ) {
        return $pos ? "Infinity" : "-Infinity";
    }

    if ( substr( $binary, 1, 2 ) eq '11' ) {
        # Bits: 1*sign 2*ignored 14*exponent 111*significand.
        # Implicit 0b100 prefix in significand.
        $coef = "" . Math::BigInt->new( "0b100" . substr( $binary, 17 ) );
        $e = unpack( "n", pack( "B*", "00" . substr( $binary, 3, 14 ) ) ) - BIAS;
    }
    else {
        # Bits: 1*sign 14*exponent 113*significand
        $coef = "" . Math::BigInt->new( "0b" . substr( $binary, 15 ) );
        $e = unpack( "n", pack( "B*", "00" . substr( $binary, 1, 14 ) ) ) - BIAS;
    }

    # Out of range is treated as zero
    if ( length($coef) > PLIM ) {
        $coef = "0";
    }

    # Shortcut on zero
    if ( $coef == 0 && $e == 0 ) {
        return $pos ? "0" : "-0";
    }

    # convert to scientific form ( e.g. 123E+4 -> 1.23E6 )
    my $adj_exp = $e + length($coef) - 1;
    # warn "# XXX COEF: $coef; EXP: $e; AEXP: $adj_exp\n";

    # exponential notation
    if ( $e > 0 || $adj_exp < -6 ) {
        # insert decimal if more than one digit
        if ( length($coef) > 1 ) {
            substr( $coef, 1, 0, "." );
        }

        return (
            ( $pos ? "" : "-" ) . $coef . "E" . ( $adj_exp >= 0 ? "+" : "" ) . $adj_exp );
    }

    # not exponential notation (integers or small negative exponents)
    else {
        # e == 0 means integer
        return $pos ? $coef : "-$coef"
          if $e == 0;

        # pad with leading zeroes if coefficient is too short
        if ( length($coef) < abs($e) ) {
            substr( $coef, 0, 0, "0" x ( abs($e) - length($coef) ) );
        }

        # maybe coefficient is exact length?
        return $pos ? "0.$coef" : "-0.$coef"
          if length($coef) == abs($e);

        # otherwise length(coef) > abs($e), so insert dot after first digit
        substr( $coef, $e, 0, "." );
        return $pos ? $coef : "-$coef";
    }
}

my ( $bidNaN, $bidPosInf, $bidNegInf ) =
  map { scalar reverse pack( "B*", $_ . ( "0" x 118 ) ) } qw/ 011111 011110 111110 /;

sub _croak { croak("Couldn't parse '$_[0]' as valid Decimal128") }

sub _erange { croak("Value '$_[0]' is out of range for Decimal128") }

sub _erounding { croak("Value '$_[0]' can't be rounded to Decimal128") }

sub _string_to_bid {
    my $s = shift;

    # Check special values
    return $bidNaN    if $s =~ /\A -? NaN \z/ix;
    return $bidPosInf if $s =~ /\A \+?Inf(?:inity)? \z/ix;
    return $bidNegInf if $s =~ /\A -Inf(?:inity)? \z/ix;

    # Parse string
    my ( $sign, $mant, $exp ) = $s =~ /\A $decimal_re \z/x;
    $sign = "" unless defined $sign;
    $exp = 0 unless defined $exp && length($exp);
    $exp =~ s{^e}{}i;

    # Throw error if unparseable
    _croak($s) unless length $exp && defined $mant;

    # Extract sign bit
    my $neg = defined($sign) && $sign eq '-' ? "1" : "0";

    # Remove leading zeroes unless "0."
    $mant =~ s{^(?:0(?!\.))+}{};

    # Locate decimal, remove it and adjust the exponent
    my $dot = index( $mant, "." );
    $mant =~ s/\.//;
    $exp += $dot - length($mant) if $dot >= 0;

    # Remove leading zeros from mantissa (after decimal point removed)
    $mant =~ s/^0+//;
    $mant = "0" unless length $mant;

    # Apply exact rounding if necessary
    if ( length($mant) > PLIM ) {
        my $plim = PLIM;
        $mant =~ s{(.{$plim})(0+)$}{$1};
        $exp += length($2) if defined $2 && length $2;
    }
    elsif ( $exp < AEMIN ) {
        $mant =~ s{(.*[1-9])(0+)$}{$1};
        $exp += length($2) if defined $2 && length $2;
    }

    # Apply clamping if possible
    if ( $mant == 0 ) {
        if ( $exp > AEMAX ) {
            $mant = "0";
            $exp = AEMAX;
        }
        elsif ( $exp < AEMIN ) {
            $mant = "0";
            $exp = AEMIN;
        }
    }
    elsif ( $exp > AEMAX && $exp - AEMAX <= PLIM - length($mant) ) {
        $mant .= "0" x ( $exp - AEMAX );
        $exp = AEMAX;
    }

    # Throw errors if result won't fit in Decimal128
    _erounding($s) if length($mant) > PLIM;
    _erange($s) if $exp > AEMAX || $exp < AEMIN;

    # Get binary representation of coefficient
    my $coef = Math::BigInt->new($mant)->as_bin;
    $coef =~ s/^0b//;

    # Get 14-bit binary representation of biased exponent
    my $biased_exp = unpack( "B*", pack( "n", $exp + BIAS ) );
    substr( $biased_exp, 0, 2, "" );

    # Choose representation based on coefficient length
    my $coef_len = length($coef);
    if ( $coef_len <= 113 ) {
        substr( $coef, 0, 0, "0" x ( 113 - $coef_len ) );
        return scalar reverse pack( "B*", $neg . $biased_exp . $coef );
    }
    elsif ( $coef_len <= 114 ) {
        substr( $coef, 0, 3, "" );
        return scalar reverse pack( "B*", $neg . "11" . $biased_exp . $coef );
    }
    else {
        _erange($s);
    }
}

#pod =method TO_JSON
#pod
#pod Returns the value as a string.
#pod
#pod If the C<BSON_EXTJSON> option is true, it will instead
#pod be compatible with MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod format, which represents it as a document as follows:
#pod
#pod     {"$numberDecimal" : "2.23372036854775807E+57"}
#pod
#pod =cut

sub TO_JSON {
    return "" . $_[0]->value unless $ENV{BSON_EXTJSON};
    return { '$numberDecimal' => "" . ($_[0]->value)  };
}

use overload (
    q{""}    => sub { $_[0]->value },
    fallback => 1,
);

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Decimal128 - BSON type wrapper for Decimal128

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    # string representation
    $decimal = bson_decimal128( "1.23456789E+1000" );

    # binary representation in BID format
    $decimal = BSON::Decimal128->new( bytes => $bid ) 

=head1 DESCRIPTION

This module provides a BSON type wrapper for Decimal128 values.

It may be initialized with either a numeric value in string form, or
with a binary Decimal128 representation (16 bytes), but not both.

Initialization from a string will throw an error if the string cannot be
parsed as a Decimal128 or if the resulting number would not fit into 128
bits.  If required, clamping or exact rounding will be applied to try to
fit the value into 128 bits.

=head1 ATTRIBUTES

=head2 value

The Decimal128 value represented as string.  If not provided, it will be
generated from the C<bytes> attribute on demand.

=head2 bytes

The Decimal128 value represented in L<Binary Integer
Decimal|https://en.wikipedia.org/wiki/Binary_Integer_Decimal> (BID) format.
If not provided, it will be generated from the C<value> attribute on
demand.

=head1 METHODS

=head2 TO_JSON

Returns the value as a string.

If the C<BSON_EXTJSON> option is true, it will instead
be compatible with MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
format, which represents it as a document as follows:

    {"$numberDecimal" : "2.23372036854775807E+57"}

=for Pod::Coverage BUILD

=head1 OVERLOADING

The stringification operator (C<"">) is overloaded to return a (normalized)
string representation. Fallback overloading is enabled.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Stefan G. <minimalist@lavabit.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Stefan G. and MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
