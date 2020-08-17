use 5.010001;
use strict;
use warnings;
no warnings 'recursion';

package BSON::PP;
# ABSTRACT: Pure Perl BSON implementation

use version;
our $VERSION = 'v1.12.2';

use B;
use Carp;
use Config;
use Scalar::Util qw/blessed looks_like_number refaddr reftype/;
use List::Util qw/first/;
use Tie::IxHash;

use BSON::Types ();
use boolean;
use mro;

use re 'regexp_pattern';

use constant {
    HAS_INT64 => $Config{use64bitint},
};

use if !HAS_INT64, "Math::BigInt";

# Max integer sizes
my $max_int32 = 2147483647;
my $min_int32 = -2147483648;
my $max_int64 =
  HAS_INT64 ? 9223372036854775807 : Math::BigInt->new("9223372036854775807");
my $min_int64 =
  HAS_INT64 ? -9223372036854775808 : Math::BigInt->new("-9223372036854775808");

#<<<
my $int_re     = qr/^(?:(?:[+-]?)(?:[0123456789]+))$/;
my $doub_re    = qr/^(?:(?i)(?:NaN|-?Inf(?:inity)?)|(?:[+-]?)(?:(?=[0123456789]|[.])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))$/;
#>>>

my $bools_re = qr/::(?:Boolean|_Bool|Bool)\z/;

use constant {

    BSON_TYPE_NAME => "CZ*",
    BSON_DOUBLE => "d<",
    BSON_STRING => "V/Z*",
    BSON_BOOLEAN => "C",
    BSON_REGEX => "Z*Z*",
    BSON_JSCODE => "",
    BSON_INT32 => "l<",
    BSON_UINT32 => "L<",
    BSON_INT64 => "q<",
    BSON_8BYTES => "a8",
    BSON_16BYTES => "a16",
    BSON_TIMESTAMP => "L<L<",
    BSON_CODE_W_SCOPE => "l<",
    BSON_REMAINING => 'a*',
    BSON_SKIP_4_BYTES => 'x4',
    BSON_OBJECTID => 'a12',
    BSON_BINARY_TYPE => 'C',
    BSON_CSTRING => 'Z*',
    BSON_MAX_DEPTH => 100,
};

sub _printable {
    my $value = shift;
    $value =~ s/([^[:print:]])/sprintf("\\x%02x",ord($1))/ge;
    return $value;
}

sub _split_re {
    my $value = shift;
    if ( $] ge 5.010 ) {
        return re::regexp_pattern($value);
    }
    else {
        $value =~ s/^\(\?\^?//;
        $value =~ s/\)$//;
        my ( $opt, $re ) = split( /:/, $value, 2 );
        $opt =~ s/\-\w+$//;
        return ( $re, $opt );
    }
}

sub _ixhash_iterator {
    my $ixhash = shift;
    my $started = 0;
    return sub {
        my $k = $started ? $ixhash->NEXTKEY : do { $started++; $ixhash->FIRSTKEY };
        return unless defined $k;
        return ($k, $ixhash->FETCH($k));
    }
}

# relying on Perl's each() is prone to action-at-a-distance effects we
# want to avoid, so we construct our own iterator for hashes
sub _hashlike_iterator {
    my $hashlike = shift;
    my @keys = keys %$hashlike;
    @keys = sort @keys
        if $ENV{BSON_TEST_SORT_HASH};
    return sub {
        my $k = shift @keys;
        return unless defined $k;
        return ($k, $hashlike->{$k});
    }
}

# XXX could be optimized down to only one substr to trim/pad
sub _bigint_to_int64 {
    my $bigint = shift;
    my $neg = $bigint < 0;
    if ( $neg ) {
        if ( $bigint < $min_int64 ) {
            return "\x80\x00\x00\x00\x00\x00\x00\x00";
        }
        $bigint = abs($bigint) - ($max_int64 + 1);
    }
    elsif ( $bigint > $max_int64 ) {
        return "\x7f\xff\xff\xff\xff\xff\xff\xff";
    }

    my $as_hex = $bigint->as_hex; # big-endian hex
    $as_hex =~ s{-?0x}{};
    my $len = length($as_hex);
    substr( $as_hex, 0, 0, "0" x ( 16 - $len ) ) if $len < 16; # pad to quad length
    my $pack = pack( "H*", $as_hex );
    $pack |= "\x80\x00\x00\x00\x00\x00\x00\x00" if $neg;
    return scalar reverse $pack;
}

sub _int64_to_bigint {
    my $bytes = reverse(shift);
    return Math::BigInt->new() if $bytes eq "\x00\x00\x00\x00\x00\x00\x00\x00";
    if ( unpack("c", $bytes) < 0 ) {
        if ( $bytes eq "\x80\x00\x00\x00\x00\x00\x00\x00" ) {
            return -1 * Math::BigInt->new( "0x" . unpack("H*",$bytes) );
        }
        else {
            return -1 * Math::BigInt->new( "0x" . unpack( "H*", ~$bytes ) ) - 1;
        }
    }
    else {
        return Math::BigInt->new( "0x" . unpack( "H*", $bytes ) );
    }
}

sub _pack_int64 {
    my $value = shift;
    my $type  = ref($value);

    # if no type, then on 64-big perl we can pack with 'q'; otherwise
    # we need to convert scalars to Math::BigInt and pack them that way.
    if ( ! $type ) {
        return pack(BSON_INT64,$value ) if HAS_INT64;
        $value = Math::BigInt->new($value);
        $type = 'Math::BigInt';
    }

    if ( $type eq 'Math::BigInt' ) {
        return _bigint_to_int64($value);
    }
    elsif ( $type eq 'Math::Int64' ) {
        return Math::Int64::int64_to_native($value);
    }
    else {
        croak "Don't know how to encode $type '$value' as an Int64.";
    }
}

sub _reftype_check {
    my $doc = shift;
    my $type = ref($doc);
    my $reftype = reftype($doc);
    die "Can't encode non-container of type '$type'" unless $reftype eq 'HASH';
    return;
}

sub _encode_bson {
    my ($doc, $opt) = @_;

    my $refaddr = refaddr($doc);
    die "circular reference detected" if $opt->{_circular}{$refaddr}++;

    $opt->{_depth} = 0 unless defined $opt->{_depth};
    $opt->{_depth}++;
    if ($opt->{_depth} > BSON_MAX_DEPTH) {
        croak "Exceeded max object depth of ". BSON_MAX_DEPTH;
    }

    my $doc_type = ref($doc);

    if ( $doc_type eq 'BSON::Raw' || $doc_type eq 'MongoDB::BSON::_EncodedDoc' ) {
        delete $opt->{_circular}{$refaddr};
        $opt->{_depth}--;
        return $doc->bson;
    }

    if ( $doc_type eq 'MongoDB::BSON::Raw' ) {
        delete $opt->{_circular}{$refaddr};
        $opt->{_depth}--;
        return $$doc;
    }

    my $iter =
        $doc_type eq 'HASH'           ? undef
      : $doc_type eq 'BSON::Doc'      ? $doc->_iterator
      : $doc_type eq 'Tie::IxHash'    ? _ixhash_iterator($doc)
      : $doc_type eq 'BSON::DBRef'    ? _ixhash_iterator( $doc->_ordered )
      : $doc_type eq 'MongoDB::DBRef' ? _ixhash_iterator( $doc->_ordered )
      :                                 do { _reftype_check($doc); undef };

    $iter //= _hashlike_iterator($doc);

    my $op_char = defined($opt->{op_char}) ? $opt->{op_char} : '';
    my $invalid =
      length( $opt->{invalid_chars} ) ? qr/[\Q$opt->{invalid_chars}\E]/ : undef;

    # Set up first key bookkeeping
    my $first_key_pending = !! defined($opt->{first_key});
    my $first_key;
    my $bson = '';

    my ($key, $value);
    while ( $first_key_pending or ( $key, $value ) = $iter->() ) {
        next if defined $first_key && $key eq $first_key;

        if ( $first_key_pending ) {
            $first_key = $key = delete $opt->{first_key};
            $value = delete $opt->{first_value};
            undef $first_key_pending;
        }

        last unless defined $key;

        croak "Key '" . _printable($key) . "' contains null character"
          unless -1 == index($key, "\0");

        substr( $key, 0, 1 ) = '$'
          if length($op_char) && substr( $key, 0, 1 ) eq $op_char;

        if ( $invalid && $key =~ $invalid ) {
            croak(
                sprintf(
                    "key '%s' has invalid character(s) '%s'",
                    $key, $opt->{invalid_chars}
                )
            );
        }

        my $utf8_key = $key;
        utf8::encode($utf8_key);
        my $type = ref $value;

        # If the type is a subtype of BSON::*, use that instead
        if ( blessed $value ) {
            if ($type !~ /\ABSON::\w+\z/) {
                my $parent = first { /\ABSON::\w+\z/ } reverse @{mro::get_linear_isa($type)};
                $type = $parent if defined $parent;
            }
        }

        # Null
        if ( !defined $value ) {
            $bson .= pack( BSON_TYPE_NAME, 0x0A, $utf8_key );
        }

        # REFERENCES/OBJECTS
        elsif ( length $type ) {

            # Array
            if ( $type eq 'ARRAY' || $type eq 'BSON::Array' ) {
                my $i = 0;
                tie( my %h, 'Tie::IxHash' );
                %h = map { $i++ => $_ } @$value;
                $bson .= pack( BSON_TYPE_NAME, 0x04, $utf8_key ) . _encode_bson( \%h, $opt );
            }

            # special-cased deprecated DBPointer
            elsif ($type eq 'BSON::DBPointer') {
                my %data;
                tie %data, 'Tie::IxHash';
                $data{'$ref'} = $value->{'ref'};
                $data{'$id'} = $value->{id};
                $bson .= pack( BSON_TYPE_NAME, 0x03, $utf8_key )
                    . _encode_bson(\%data, $opt);
            }

            # Document
            elsif ($type eq 'HASH'
                || $type eq 'BSON::Doc'
                || $type eq 'BSON::Raw'
                || $type eq 'MongoDB::BSON::_EncodedDoc'
                || $type eq 'Tie::IxHash'
                || $type eq 'MongoDB::BSON::Raw'
                || $type eq 'BSON::DBRef'
                || $type eq 'MongoDB::DBRef')
            {
                $bson .= pack( BSON_TYPE_NAME, 0x03, $utf8_key ) . _encode_bson($value, $opt);
            }

            # Regex
            elsif ( $type eq 'Regexp' ) {
                my ( $re, $flags ) = _split_re($value);
                $bson .= pack( BSON_TYPE_NAME.BSON_REGEX, 0x0B, $utf8_key, $re, join( "", sort grep /^(i|m|x|l|s|u)$/, split( //, $flags ) ));
            }
            elsif ( $type eq 'BSON::Regex' || $type eq 'MongoDB::BSON::Regexp' ) {
                my ( $re, $flags ) = @{$value}{qw/pattern flags/};
                $bson .= pack( BSON_TYPE_NAME.BSON_REGEX, 0x0B, $utf8_key, $re, $flags) ;
            }

            # ObjectId
            elsif ( $type eq 'BSON::OID' || $type eq 'BSON::ObjectId' ) {
                $bson .= pack( BSON_TYPE_NAME.BSON_OBJECTID, 0x07, $utf8_key, $value->oid );
            }
            elsif ( $type eq 'MongoDB::OID' ) {
                $bson .= pack( BSON_TYPE_NAME."H*", 0x07, $utf8_key, $value->value );
            }

            # Datetime
            elsif ( $type eq 'BSON::Time' ) {
                $bson .= pack( BSON_TYPE_NAME, 0x09, $utf8_key ) . _pack_int64( $value->value );
            }
            elsif ( $type eq 'Time::Moment' ) {
                $bson .= pack( BSON_TYPE_NAME, 0x09, $utf8_key ) . _pack_int64( int( $value->epoch * 1000 + $value->millisecond ) );
            }
            elsif ( $type eq 'DateTime' ) {
                if ( $value->time_zone->name eq 'floating' ) {
                    warn("saving floating timezone as UTC");
                }
                $bson .= pack( BSON_TYPE_NAME, 0x09, $utf8_key ) . _pack_int64( int( $value->hires_epoch * 1000 ) );
            }
            elsif ( $type eq 'DateTime::Tiny' ) {
                require Time::Local;
                my $epoch = Time::Local::timegm(
                    $value->second, $value->minute,    $value->hour,
                    $value->day,    $value->month - 1, $value->year,
                );
                $bson .= pack( BSON_TYPE_NAME, 0x09, $utf8_key ) . _pack_int64( $epoch * 1000 );
            }
            elsif ( $type eq 'Mango::BSON::Time' ) {
                $bson .= pack( BSON_TYPE_NAME, 0x09, $utf8_key ) . _pack_int64( $value->{time} );
            }

            # Timestamp
            elsif ( $type eq 'BSON::Timestamp' ) {
                $bson .= pack( BSON_TYPE_NAME.BSON_TIMESTAMP, 0x11, $utf8_key, $value->increment, $value->seconds );
            }
            elsif ( $type eq 'MongoDB::Timestamp' ){
                $bson .= pack( BSON_TYPE_NAME.BSON_TIMESTAMP, 0x11, $utf8_key, $value->inc, $value->sec );
            }

            # MinKey
            elsif ( $type eq 'BSON::MinKey' || $type eq 'MongoDB::MinKey' ) {
                $bson .= pack( BSON_TYPE_NAME, 0xFF, $utf8_key );
            }

            # MaxKey
            elsif ( $type eq 'BSON::MaxKey' || $type eq 'MongoDB::MaxKey' ) {
                $bson .= pack( BSON_TYPE_NAME, 0x7F, $utf8_key );
            }

            # Binary (XXX need to add string ref support)
            elsif ($type eq 'SCALAR'
                || $type eq 'BSON::Bytes'
                || $type eq 'BSON::Binary'
                || $type eq 'MongoDB::BSON::Binary' )
            {
                my $data =
                    $type eq 'SCALAR'      ? $$value
                : $type eq 'BSON::Bytes' ? $value->data
                : $type eq 'MongoDB::BSON::Binary' ? $value->data
                :                          pack( "C*", @{ $value->data } );
                my $subtype = $type eq 'SCALAR' ? 0 : $value->subtype;
                my $len = length($data);
                if ( $subtype == 2 ) {
                    $bson .=
                    pack( BSON_TYPE_NAME . BSON_INT32 . BSON_BINARY_TYPE . BSON_INT32 . BSON_REMAINING,
                        0x05, $utf8_key, $len + 4, $subtype, $len, $data );
                }
                else {
                    $bson .= pack( BSON_TYPE_NAME . BSON_INT32 . BSON_BINARY_TYPE . BSON_REMAINING,
                        0x05, $utf8_key, $len, $subtype, $data );
                }
            }

            # Code
            elsif ( $type eq 'BSON::Code' || $type eq 'MongoDB::Code' ) {
                my $code = $value->code;
                utf8::encode($code);
                $code = pack(BSON_STRING,$code);
                if ( ref( $value->scope ) eq 'HASH' ) {
                    my $scope = _encode_bson( $value->scope, $opt );
                    $bson .=
                        pack( BSON_TYPE_NAME.BSON_CODE_W_SCOPE, 0x0F, $utf8_key, (4 + length($scope) + length($code)) ) . $code . $scope;
                }
                else {
                    $bson .= pack( BSON_TYPE_NAME, 0x0D, $utf8_key) . $code;
                }
            }

            # Boolean
            elsif ( $type eq 'boolean' || $type =~ $bools_re ) {
                $bson .= pack( BSON_TYPE_NAME.BSON_BOOLEAN, 0x08, $utf8_key, ( $value ? 1 : 0 ) );
            }

            # String (explicit)
            elsif ( $type eq 'BSON::String' || $type eq 'BSON::Symbol') {
                $value = $value->value;
                utf8::encode($value);
                $bson .= pack( BSON_TYPE_NAME.BSON_STRING, 0x02, $utf8_key, $value );
            }
            elsif ( $type eq 'MongoDB::BSON::String' ) {
                $value = $$value;
                utf8::encode($value);
                $bson .= pack( BSON_TYPE_NAME.BSON_STRING, 0x02, $utf8_key, $value );
            }

            # Int64 (XXX and eventually BigInt)
            elsif ( $type eq 'BSON::Int64' || $type eq 'Math::BigInt' || $type eq 'Math::Int64' )
            {
                if ( $value > $max_int64 || $value < $min_int64 ) {
                    croak("BSON can only handle 8-byte integers. Key '$key' is '$value'");
                }

                # unwrap BSON::Int64; it could be Math::BigInt, etc.
                if ( $type eq 'BSON::Int64' ) {
                    $value = $value->value;
                }

                $bson .= pack( BSON_TYPE_NAME, 0x12, $utf8_key ) . _pack_int64($value);
            }

            elsif ( $type eq 'BSON::Int32' ) {
                $bson .= pack( BSON_TYPE_NAME . BSON_INT32, 0x10, $utf8_key, $value->value );
            }

            # Double (explicit)
            elsif ( $type eq 'BSON::Double' ) {
                $bson .= pack( BSON_TYPE_NAME.BSON_DOUBLE, 0x01, $utf8_key, $value/1.0 );
            }

            # Decimal128
            elsif ( $type eq 'BSON::Decimal128' ) {
                $bson .= pack( BSON_TYPE_NAME.BSON_16BYTES, 0x13, $utf8_key, $value->bytes );
            }

            # Unsupported type
            else  {
                croak("For key '$key', can't encode value of type '$type'");
            }
        }

        # SCALAR
        else {
            # If a numeric value exists based on internal flags, use it;
            # otherwise, if prefer_numeric is true and it looks like a
            # number, then coerce to a number of the right type;
            # otherwise, leave it as a string

            my $flags = B::svref_2object(\$value)->FLAGS;

            if ( $flags & B::SVf_NOK() ) {
                $bson .= pack( BSON_TYPE_NAME.BSON_DOUBLE, 0x01, $utf8_key, $value );
            }
            elsif ( $flags & B::SVf_IOK() ) {
                # Force numeric; fixes dual-vars comparison bug on old Win32s
                $value = 0+$value;
                if ( $value > $max_int64 || $value < $min_int64 ) {
                    croak("BSON can only handle 8-byte integers. Key '$key' is '$value'");
                }
                elsif ( $value > $max_int32 || $value < $min_int32 ) {
                    $bson .= pack( BSON_TYPE_NAME, 0x12, $utf8_key ) . _pack_int64($value);
                }
                else {
                    $bson .= pack( BSON_TYPE_NAME . BSON_INT32, 0x10, $utf8_key, $value );
                }
            }
            elsif ( $opt->{prefer_numeric} && looks_like_number($value) ) {
                # Looks like int: type heuristic based on size
                if ( $value =~ $int_re ) {
                    if ( $value > $max_int64 || $value < $min_int64 ) {
                        croak("BSON can only handle 8-byte integers. Key '$key' is '$value'");
                    }
                    elsif ( $value > $max_int32 || $value < $min_int32 ) {
                        $bson .= pack( BSON_TYPE_NAME, 0x12, $utf8_key ) . _pack_int64($value);
                    }
                    else {
                        $bson .= pack( BSON_TYPE_NAME . BSON_INT32, 0x10, $utf8_key, $value );
                    }
                }

                # Looks like double
                elsif ( $value =~ $doub_re ) {
                    $bson .= pack( BSON_TYPE_NAME.BSON_DOUBLE, 0x01, $utf8_key, $value );
                }

                # looks_like_number true, but doesn't match int/double
                # regexes, so as a last resort we leave as string
                else {
                    utf8::encode($value);
                    $bson .= pack( BSON_TYPE_NAME.BSON_STRING, 0x02, $utf8_key, $value );
                }
            }
            else {
                # Not coercing or didn't look like a number
                utf8::encode($value);
                $bson .= pack( BSON_TYPE_NAME.BSON_STRING, 0x02, $utf8_key, $value );
            }
        }
    }

    delete $opt->{_circular}{$refaddr};
    $opt->{_depth}--;

    return pack( BSON_INT32, length($bson) + 5 ) . $bson . "\0";
}

my %FIELD_SIZES = (
    0x01 => 8,
    0x02 => 5,
    0x03 => 5,
    0x04 => 5,
    0x05 => 5,
    0x06 => 0,
    0x07 => 12,
    0x08 => 1,
    0x09 => 8,
    0x0A => 0,
    0x0B => 2,
    0x0C => 17,
    0x0D => 5,
    0x0E => 5,
    0x0F => 11,
    0x10 => 4,
    0x11 => 8,
    0x12 => 8,
    0x13 => 16,
    0x7F => 0,
    0xFF => 0,
);

my $ERR_UNSUPPORTED = "unsupported BSON type \\x%X for key '%s'.  Are you using the latest version of BSON.pm?";
my $ERR_TRUNCATED = "premature end of BSON field '%s' (type 0x%x)";
my $ERR_LENGTH = "BSON field '%s' (type 0x%x) has invalid length: wanted %d, got %d";
my $ERR_MISSING_NULL = "BSON field '%s' (type 0x%x) missing null terminator";
my $ERR_BAD_UTF8 = "BSON field '%s' (type 0x%x) contains invalid UTF-8";
my $ERR_NEG_LENGTH = "BSON field '%s' (type 0x%x) contains negative length";
my $ERR_BAD_OLDBINARY = "BSON field '%s' (type 0x%x, subtype 0x02) is invalid";

sub __dump_bson {
    my $bson = unpack("H*", shift);
    my @pairs = $bson=~ m/(..)/g;
    return join(" ", @pairs);
}

sub _decode_bson {
    my ($bson, $opt) = @_;
    if ( !defined $bson ) {
        croak("Decode argument must not be undef");
    }
    $opt->{_depth} = 0 unless defined $opt->{_depth};
    $opt->{_depth}++;
    if ($opt->{_depth} > BSON_MAX_DEPTH) {
        croak "Exceeded max object depth of ". BSON_MAX_DEPTH;
    }
    my $blen= length($bson);
    my $len = unpack( BSON_INT32, $bson );
    if ( length($bson) != $len ) {
        croak("Incorrect length of the bson string (got $blen, wanted $len)");
    }
    if ( chop($bson) ne "\x00" ) {
        croak("BSON document not null terminated");
    }
    $bson = substr $bson, 4;
    my @array = ();
    my %hash = ();
    tie( %hash, 'Tie::IxHash' ) if $opt->{ordered};
    my ($type, $key, $value);
    while ($bson) {
        ( $type, $key, $bson ) = unpack( BSON_TYPE_NAME.BSON_REMAINING, $bson );
        utf8::decode($key);

        # Check type and truncation
        my $min_size = $FIELD_SIZES{$type};
        if ( !defined $min_size ) {
            croak( sprintf( $ERR_UNSUPPORTED, $type, $key ) );
        }
        if ( length($bson) < $min_size ) {
            croak( sprintf( $ERR_TRUNCATED, $key, $type ) );
        }

        # Double
        if ( $type == 0x01 ) {
            ( $value, $bson ) = unpack( BSON_DOUBLE.BSON_REMAINING, $bson );
            $value = BSON::Double->new( value => $value ) if $opt->{wrap_numbers};
        }

        # String and Symbol (deprecated); Symbol will be convert to String
        elsif ( $type == 0x02 || $type == 0x0E ) {
            ( $len, $bson ) = unpack( BSON_INT32 . BSON_REMAINING, $bson );
            if ( length($bson) < $len || substr( $bson, $len - 1, 1 ) ne "\x00" ) {
                croak( sprintf( $ERR_MISSING_NULL, $key, $type ) );
            }
            ( $value, $bson ) = unpack( "a$len" . BSON_REMAINING, $bson );
            chop($value); # remove trailing \x00
            if ( !utf8::decode($value) ) {
                croak( sprintf( $ERR_BAD_UTF8, $key, $type ) );
            }
            $value = BSON::String->new( value => $value ) if $opt->{wrap_strings};
        }

        # Document and Array
        elsif ( $type == 0x03 || $type == 0x04 ) {
            my $len = unpack( BSON_INT32, $bson );
            $value = _decode_bson( substr( $bson, 0, $len ), { %$opt, _decode_array => $type == 0x04}  );
            if ( $opt->{wrap_dbrefs} && $type == 0x03 && exists $value->{'$id'} && exists $value->{'$ref'} ) {
                $value = BSON::DBRef->new( %$value );
            }
            $bson = substr( $bson, $len, length($bson) - $len );
        }

        # Binary
        elsif ( $type == 0x05 ) {
            my ( $len, $btype ) = unpack( BSON_INT32 . BSON_BINARY_TYPE, $bson );
            substr( $bson, 0, 5, '' );

            if ( $len < 0 ) {
                croak( sprintf( $ERR_NEG_LENGTH, $key, $type ) );
            }
            if ( $len > length($bson) ) {
                croak( sprintf( $ERR_TRUNCATED, $key, $type ) );
            }

            my $binary = substr( $bson, 0, $len, '' );

            if ( $btype == 2 ) {
                if ( $len < 4 ) {
                    croak( sprintf( $ERR_BAD_OLDBINARY, $key, $type ) );
                }

                my $sublen = unpack( BSON_INT32, $binary );
                if ( $sublen != length($binary) - 4 ) {
                    croak( sprintf( $ERR_BAD_OLDBINARY, $key, $type ) );
                }

                substr( $binary, 0, 4, '' );
            }

            $value = BSON::Bytes->new( subtype => $btype, data => $binary );
        }

        # Undef (deprecated)
        elsif ( $type == 0x06 ) {
            $value = undef;
        }

        # ObjectId
        elsif ( $type == 0x07 ) {
            ( my $oid, $bson ) = unpack( BSON_OBJECTID.BSON_REMAINING, $bson );
            $value = BSON::OID->new(oid => $oid);
        }

        # Boolean
        elsif ( $type == 0x08 ) {
            ( my $bool, $bson ) = unpack( BSON_BOOLEAN.BSON_REMAINING, $bson );
            croak("BSON boolean must be 0 or 1. Key '$key' is $bool")
                unless $bool == 0 || $bool == 1;
            $value = boolean( $bool );
        }

        # Datetime
        elsif ( $type == 0x09 ) {
            if ( HAS_INT64 ) {
                ($value, $bson) = unpack(BSON_INT64.BSON_REMAINING,$bson);
            }
            else {
                ($value, $bson) = unpack(BSON_8BYTES.BSON_REMAINING,$bson);
                $value = _int64_to_bigint($value);
            }
            $value = BSON::Time->new( value => $value );
            my $dt_type = $opt->{dt_type};
            if ( defined $dt_type && $dt_type ne 'BSON::Time' ) {
                $value =
                    $dt_type eq 'Time::Moment'      ? $value->as_time_moment
                  : $dt_type eq 'DateTime'          ? $value->as_datetime
                  : $dt_type eq 'DateTime::Tiny'    ? $value->as_datetime_tiny
                  : $dt_type eq 'Mango::BSON::Time' ? $value->as_mango_time
                  :   croak("Unsupported dt_type '$dt_type'");
            }
        }

        # Null
        elsif ( $type == 0x0A ) {
            $value = undef;
        }

        # Regex
        elsif ( $type == 0x0B ) {
            ( my $re, my $op, $bson ) = unpack( BSON_CSTRING.BSON_CSTRING.BSON_REMAINING, $bson );
            $value = BSON::Regex->new( pattern => $re, flags => $op );
        }

        # DBPointer (deprecated)
        elsif ( $type == 0x0C ) {
            ( $len, $bson ) = unpack( BSON_INT32 . BSON_REMAINING, $bson );
            if ( length($bson) < $len || substr( $bson, $len - 1, 1 ) ne "\x00" ) {
                croak( sprintf( $ERR_MISSING_NULL, $key, $type ) );
            }
            ( my ($ref), $bson ) = unpack( "a$len" . BSON_REMAINING, $bson );
            chop($ref); # remove trailing \x00
            if ( !utf8::decode($ref) ) {
                croak( sprintf( $ERR_BAD_UTF8, $key, $type ) );
            }

            ( my ($oid), $bson ) = unpack( BSON_OBJECTID . BSON_REMAINING, $bson );
            $value = BSON::DBRef->new( '$ref' => $ref, '$id' => BSON::OID->new( oid => $oid ) );
        }

        # Code
        elsif ( $type == 0x0D ) {
            ( $len, $bson ) = unpack( BSON_INT32 . BSON_REMAINING, $bson );
            if ( length($bson) < $len || substr( $bson, $len - 1, 1 ) ne "\x00" ) {
                croak( sprintf( $ERR_MISSING_NULL, $key, $type ) );
            }
            ( $value, $bson ) = unpack( "a$len" . BSON_REMAINING, $bson );
            chop($value); # remove trailing \x00
            if ( !utf8::decode($value) ) {
                croak( sprintf( $ERR_BAD_UTF8, $key, $type ) );
            }
            $value = BSON::Code->new( code => $value );
        }

        # Code with scope
        elsif ( $type == 0x0F ) {
            my $len = unpack( BSON_INT32, $bson );

            # validate length
            if ( $len < 0 ) {
                croak( sprintf( $ERR_NEG_LENGTH, $key, $type ) );
            }
            if ( $len > length($bson) ) {
                croak( sprintf( $ERR_TRUNCATED, $key, $type ) );
            }
            if ( $len < 5 ) {
                croak( sprintf( $ERR_LENGTH, $key, $type, 5, $len ) );
            }

            # extract code and scope and chop off leading length
            my $codewscope = substr( $bson, 0, $len, '' );
            substr( $codewscope, 0, 4, '' );

            # extract code ( i.e. string )
            my $strlen = unpack( BSON_INT32, $codewscope );
            substr( $codewscope, 0, 4, '' );

            if ( length($codewscope) < $strlen || substr( $codewscope, -1, 1 ) ne "\x00" ) {
                croak( sprintf( $ERR_MISSING_NULL, $key, $type ) );
            }

            my $code = substr($codewscope, 0, $strlen, '' );
            chop($code); # remove trailing \x00
            if ( !utf8::decode($code) ) {
                croak( sprintf( $ERR_BAD_UTF8, $key, $type ) );
            }

            if ( length($codewscope) < 5 ) {
                croak( sprintf( $ERR_TRUNCATED, $key, $type ) );
            }

            # extract scope
            my $scopelen = unpack( BSON_INT32, $codewscope );
            if ( length($codewscope) < $scopelen || substr( $codewscope, $scopelen - 1, 1 ) ne "\x00" ) {
                croak( sprintf( $ERR_MISSING_NULL, $key, $type ) );
            }

            my $scope = _decode_bson( $codewscope, { %$opt, _decode_array => 0} );

            $value = BSON::Code->new( code => $code, scope => $scope );
        }

        # Int32
        elsif ( $type == 0x10 ) {
            ( $value, $bson ) = unpack( BSON_INT32.BSON_REMAINING, $bson );
            $value = BSON::Int32->new( value => $value ) if $opt->{wrap_numbers};
        }

        # Timestamp
        elsif ( $type == 0x11 ) {
            ( my $sec, my $inc, $bson ) = unpack( BSON_UINT32.BSON_UINT32.BSON_REMAINING, $bson );
            $value = BSON::Timestamp->new( $inc, $sec );
        }

        # Int64
        elsif ( $type == 0x12 ) {
            if ( HAS_INT64 ) {
                ($value, $bson) = unpack(BSON_INT64.BSON_REMAINING,$bson);
            }
            else {
                ($value, $bson) = unpack(BSON_8BYTES.BSON_REMAINING,$bson);
                $value = _int64_to_bigint($value);
            }
            $value = BSON::Int64->new( value => $value ) if $opt->{wrap_numbers};
        }

        # Decimal128
        elsif ( $type == 0x13 ) {
            ( my $bytes, $bson ) = unpack( BSON_16BYTES.BSON_REMAINING, $bson );
            $value = BSON::Decimal128->new( bytes => $bytes );
        }

        # MinKey
        elsif ( $type == 0xFF ) {
            $value = BSON::MinKey->new;
        }

        # MaxKey
        elsif ( $type == 0x7F ) {
            $value = BSON::MaxKey->new;
        }

        # ???
        else {
            # Should have already been caught in the minimum length check,
            # but just in case not:
            croak( sprintf( $ERR_UNSUPPORTED, $type, $key ) );
        }

        if ( $opt->{_decode_array} ) {
            push @array, $value;
        }
        else {
            $hash{$key} = $value;
        }
    }
    $opt->{_depth}--;
    return $opt->{_decode_array} ? \@array : \%hash;
}

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::PP - Pure Perl BSON implementation

=head1 VERSION

version v1.12.2

=head1 DESCRIPTION

This module contains the pure-Perl implementation for BSON encoding and
decoding.  There is no public API.  Use the L<BSON> module and it will
choose the best implementation for you.

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
