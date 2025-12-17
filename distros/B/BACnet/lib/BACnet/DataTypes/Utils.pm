#!/usr/bin/perl

package BACnet::DataTypes::Utils;

use warnings;
use strict;

use POSIX;

require BACnet::DataTypes::BitString;
require BACnet::DataTypes::Bool;
require BACnet::DataTypes::Date;
require BACnet::DataTypes::Double;
require BACnet::DataTypes::Enum;
require BACnet::DataTypes::Int;
require BACnet::DataTypes::Null;
require BACnet::DataTypes::ObjectIdentifier;
require BACnet::DataTypes::OctetString;
require BACnet::DataTypes::Real;
require BACnet::DataTypes::SequenceValue;
require BACnet::DataTypes::SequenceOfValues;
require BACnet::DataTypes::Time;
require BACnet::DataTypes::UnsignedInt;
require BACnet::DataTypes::CharString;
require BACnet::DataTypes::Choice;
require BACnet::DataTypes::DataType;

#BACnet tags of dataTypes (p. 378 in doc)
use constant {
    NULL_TAG             => 0x00,
    BOOL_TAG             => 0x01,
    UNSIGNED_INT_TAG     => 0x02,
    SIGNED_INT_TAG       => 0x03,
    REAL_TAG             => 0x04,
    DOUBLE_TAG           => 0x05,
    OCTET_STRING_TAG     => 0x06,
    CHARACTER_STRING_TAG => 0x07,
    BIT_STRING_TAG       => 0x08,
    ENUMERATED_TAG       => 0x09,
    DATE_TAG             => 0x0A,
    TIME_TAG             => 0x0B,
    OBJECT_ID_TAG        => 0x0C,
    EXTENDED_TAG         => 0x0F
};

use constant {
    OPENING_LVT => 0x06,
    CLOSING_LVT => 0x07,
};

#generally useful constants
use constant { BYTE_MODULAR => ( 2**8 ) };

use constant {
    LVT_TRD_EXTENSION_MIN_SIZE => 65536,
    LVT_SND_EXTENSION_MIN_SIZE => 254,
    LVT_FST_EXTENSION_MIN_SIZE => 5,
    LVT_TRD_EXTENDER           => 255,
    LVT_SND_EXTENDER           => 254,
    LVT_EXTENDER_TAG           => 0x05,
};

use constant { MAX_POSSIBLE_HEAD_SIZE => 7, };

our %tag_to_class = (
    NULL_TAG()             => 'BACnet::DataTypes::Null',
    BOOL_TAG()             => 'BACnet::DataTypes::Bool',
    UNSIGNED_INT_TAG()     => 'BACnet::DataTypes::UnsignedInt',
    SIGNED_INT_TAG()       => 'BACnet::DataTypes::Int',
    REAL_TAG()             => 'BACnet::DataTypes::Real',
    DOUBLE_TAG()           => 'BACnet::DataTypes::Double',
    OCTET_STRING_TAG()     => 'BACnet::DataTypes::OctetString',
    CHARACTER_STRING_TAG() => 'BACnet::DataTypes::CharString',
    BIT_STRING_TAG()       => 'BACnet::DataTypes::BitString',
    ENUMERATED_TAG()       => 'BACnet::DataTypes::Enum',
    DATE_TAG()             => 'BACnet::DataTypes::Date',
    TIME_TAG()             => 'BACnet::DataTypes::Time',
    OBJECT_ID_TAG()        => 'BACnet::DataTypes::ObjectIdentifier',
);

our @dt_types = ( NULL_TAG .. OBJECT_ID_TAG );

sub _is_normalized_bool {
    my ($bool_in) = @_;

    if ( $bool_in != 0 && $bool_in != 1 ) {
        return 0;
    }

    return 1;
}

sub _normalize_bool {
    my ($bool_in) = @_;

    if ( $bool_in != 0 && $bool_in != 1 ) {
        $bool_in = 1;    #0 = FALSE, everything else = TRUE
    }

    return $bool_in;
}

sub _encode_int {

    my ($input_int) = @_;
    my ( $len_in_octets, $encoded_int );

    if ( $input_int < 0 ) {
        ( $len_in_octets, $encoded_int ) = _encode_negative_int( $input_int, 1 );
    }
    else {
        ( $len_in_octets, $encoded_int ) =
          _encode_nonnegative_int( $input_int, 1 );
    }

    return ( $len_in_octets, $encoded_int );
}

sub _encode_int_octet_undef {
    my ( $input_int, $undef_identifier ) = @_;

    if ( !defined $input_int ) {
        return pack( 'C', $undef_identifier );
    }

    return pack( 'C', $input_int );
}

sub _encode_int_octet {
    my ($input_int) = @_;
    return pack( 'C', _encode_int($input_int) & 0xFF );
}

sub _encode_nonnegative_int {

    my ( $input_int, $sign_wrap ) = @_;
    my @encoded       = ();
    my $len_in_octets = 0;

    while (1) {
        push( @encoded, pack( 'C', $input_int % BYTE_MODULAR ) );

        $input_int = floor( $input_int / BYTE_MODULAR );

        $len_in_octets++;

        if ( $input_int == 0 ) {
            last;
        }
    }

    if ( defined($sign_wrap)
        && ( unpack( 'C', $encoded[-1] ) & 0x80 ) == 0x80 )
    {
        push( @encoded, pack( 'C', 0 ) );
        $len_in_octets++;
    }

    return ( $len_in_octets, join( '', ( reverse @encoded ) ) );
}

sub _encode_negative_int {

    my ( $input_int, $sign_wrap ) = @_;

    my $to_encode     = -$input_int - 1;
    my @encoded       = ();
    my $len_in_octets = 0;

    while (1) {
        push( @encoded,
            pack( 'C', ( ~int( $to_encode % BYTE_MODULAR ) ) & 0xFF ) )
          ; #0xFF is here in case of overflow during conversion cause by inverting whole int not just 32 bytes

        $to_encode = floor( $to_encode / BYTE_MODULAR );

        $len_in_octets++;

        if ( $to_encode == 0 ) {
            last;
        }
    }

    if (
        ( defined($sign_wrap) && ( unpack( 'C', $encoded[-1] ) & 0x80 ) == 0 ) )
    {
        push @encoded, pack( 'C', 0xFF );
        $len_in_octets++;
    }

    return ( $len_in_octets, join( '', ( reverse @encoded ) ) );
}

sub _decode_int {
    my ($coded_int) = @_;

    my $first_octet = unpack( 'C', substr( $coded_int, 0, 1 ) );

    my $result = 0;
    if ( ( $first_octet & 0x80 ) == 0x80 ) {
        $result = _decode_negative_int($coded_int);
    }
    else {
        $result = _decode_nonnegative_int($coded_int);
    }
    return $result;
}

sub _decode_int_octet_undef {
    my ( $coded_int, $undef_identifier ) = @_;

    if ( $coded_int eq pack( 'C', $undef_identifier ) ) {
        return undef;
    }

    return unpack( 'C', $coded_int );
}

sub _decode_nonnegative_int {
    my ($coded_int) = @_;
    my @data = unpack( 'C*', $coded_int );

    return _decode_nonnegative_int_b(@data);
}

sub _decode_nonnegative_int_b {

    my @data   = @_;
    my $result = 0;

    for ( my $i = scalar(@data) - 1 ; $i >= 0 ; $i-- ) {
        $result += $data[$i] * ( 256**( scalar(@data) - $i - 1 ) );
    }

    return $result;
}

sub _decode_negative_int {
    my ($coded_int) = @_;

    my @data   = unpack( 'C*', $coded_int );
    my $result = 0;

    for ( my $i = scalar(@data) - 1 ; $i >= 0 ; $i-- ) {
        my $inverted = ( ~$data[$i] ) & 0xFF;
        $result += $inverted * ( 256**( scalar(@data) - $i - 1 ) );
    }

    return -( $result + 1 );
}

sub _upper_bound_division {
    my ( $nominator, $denominator ) = @_;

    my $result = POSIX::ceil( $nominator / $denominator );

    return $result;
}

sub _add_coma {
    my ($string) = @_;

    if ( $string ne "" ) {
        return "$string, ";
    }

    return $string;
}

sub _extend_headache {
    my ( $headache, $error ) = @_;

    $headache = _add_coma($headache);
    $headache .= $error;

    return $headache;

}

sub _get_head_length {

    my ($data_in) = @_;

    my $potential_head = _get_potential_head($data_in);

    my @bytes = unpack( "C*", $potential_head );

    return _get_head_length_b(@bytes);
}

sub _get_head_length_b {

    my (@bytes) = @_;
    my $len = 1;

    if ( !defined $bytes[ $len - 1 ] ) {
        return -1;
    }

    if ( _is_tag_extended( $bytes[ $len - 1 ] ) ) {
        $len++;
    }

    if ( ( $bytes[0] & 0x07 ) == LVT_EXTENDER_TAG ) {
        $len++;

        if ( !defined $bytes[ $len - 1 ] ) {
            return -1;
        }

        if ( $bytes[ $len - 1 ] == LVT_TRD_EXTENDER ) {
            $len += 4;
        }
        elsif ( $bytes[ $len - 1 ] == LVT_SND_EXTENDER ) {
            $len += 2;
        }
    }

    return $len;
}

sub _get_head_tag {

    my ($data_in) = @_;

    my $potential_head = _get_potential_head($data_in);

    my @bytes = unpack( "C*", $potential_head );

    return _get_head_tag_b(@bytes);
}

sub _get_head_tag_b {

    my (@bytes) = @_;

    if ( !defined $bytes[0] ) {
        return -1;
    }

    my $tag = ( $bytes[0] & 0xF0 ) >> 4;

    if ( $tag == EXTENDED_TAG ) {
        if ( !defined $bytes[1] ) {
            return -1;
        }

        $tag = $bytes[1];
    }

    return $tag;
}

sub _get_head_ac_class {

    my ($data_in) = @_;

    my $potential_head = _get_potential_head($data_in);

    my @bytes = unpack( "C*", $potential_head );

    return _get_head_ac_class_b(@bytes);

}

sub _get_head_ac_class_b {

    my (@bytes) = @_;

    if ( !defined $bytes[0] ) {
        return -1;
    }

    return ( ( $bytes[0] & 0x08 ) >> 3 );
}

sub _get_head_lvt {

    my ($data_in) = @_;

    my $potential_head = _get_potential_head($data_in);

    my @bytes = unpack( "C*", $potential_head );

    return _get_head_lvt_b(@bytes);
}

sub _get_head_lvt_b {

    my (@bytes) = @_;

    if ( !defined $bytes[0] ) {
        return -1;
    }

    my $lvt = $bytes[0] & 0x07;

    if ( $lvt == LVT_EXTENDER_TAG ) {

        my $lvt_ext_position = 1;

        if ( _is_tag_extended( $bytes[0] ) ) {
            $lvt_ext_position++;
        }

        if ( !defined $bytes[$lvt_ext_position] ) {
            return -1;
        }

        if ( $bytes[$lvt_ext_position] == LVT_TRD_EXTENDER ) {

            if ( !defined $bytes[ $lvt_ext_position + 1 + 3 ] ) {
                return -1;
            }

            $lvt = _decode_nonnegative_int_b(
                @bytes[
                  ( $lvt_ext_position + 1 ) ... ( $lvt_ext_position + 1 + 3 )
                ]
            );
        }
        elsif ( $bytes[$lvt_ext_position] == LVT_SND_EXTENDER ) {

            if ( !defined $bytes[ $lvt_ext_position + 1 + 1 ] ) {
                return -1;
            }

            $lvt = _decode_nonnegative_int_b(
                @bytes[
                  ( $lvt_ext_position + 1 ) ... ( $lvt_ext_position + 1 + 1 )
                ]
            );

        }
        else {
            $lvt = _decode_nonnegative_int_b(
                @bytes[ ($lvt_ext_position) ... ($lvt_ext_position) ] );

        }
    }

    return $lvt;
}

sub _is_lvt_extended {

    my ($data_in) = @_;

    my $potential_head = _get_potential_head($data_in);
    my @bytes          = unpack( "C*", $potential_head );

    if ( !defined $bytes[0] ) {
        return -1;
    }

    my $lvt = $bytes[0] & 0x07;

    if ( $lvt == LVT_EXTENDER_TAG ) {
        return 1;
    }

    return 0;
}

sub _is_context_sequence {

    my ($data_in) = @_;

    if (   _get_head_ac_class($data_in) == 1
        && _get_head_lvt($data_in) == OPENING_LVT
        && _is_lvt_extended($data_in) == 0 )
    {
        return 1;
    }

    return 0;
}

sub _is_end_of_context_sequence {

    my ($data_in) = @_;

    if (   _get_head_ac_class($data_in) == 1
        && _get_head_lvt($data_in) == CLOSING_LVT
        && _is_lvt_extended($data_in) == 0 )
    {
        return 1;
    }

    return 0;
}

sub _parse_any_dt
{    #actually do not work on ever single dt, just on primitive ones

    my ($data_in) = @_;

    my $potential_head = _get_potential_head($data_in);

    my $tag      = _get_head_tag($potential_head);
    my $dt_class = $tag_to_class{$tag};

    if ( !defined $dt_class ) {
        return undef;
    }

    my $len = _get_head_length($potential_head);

    if ( $tag != BOOL_TAG ) {
        $len += _get_head_lvt($potential_head);
    }

    return $dt_class->parse( substr( $data_in, 0, $len ) );
}

sub _parse_context_dt {
    my ( $data_in, $bone ) = @_;


    if (   $bone->{dt} eq 'BACnet::DataTypes::SequenceOfValues'
        || $bone->{dt} eq 'BACnet::DataTypes::SequenceValue'
        || $bone->{dt} eq 'BACnet::DataTypes::Choice' )
    {
        return $bone->{dt}
          ->parse( $data_in, $bone->{skeleton}, $bone->{wrapped} );
    }

    return $bone->{dt}->parse(
        substr(
            $data_in, 0, _get_head_lvt($data_in) + _get_head_length($data_in)
        ),
    );

}

sub _get_head_metadata {
    my ($data_in) = @_;

    my $potential_head = _get_potential_head($data_in);

    my @bytes = unpack( "C*", $potential_head );

    my %head_metadata = (
        length   => _get_head_length_b(@bytes),
        tag      => _get_head_tag_b(@bytes),
        ac_class => _get_head_ac_class_b(@bytes),
        lvt      => _get_head_lvt_b(@bytes),
    );

    return %head_metadata;

}

sub _is_tag_extended {
    my ($base_head) = @_;
    return ( ( ( $base_head & 0xF0 ) >> 4 ) == EXTENDED_TAG );
}

sub _correct_head {
    my %args = (
        data_in            => undef,
        expected_tag       => undef,
        expected_length    => undef,
        lvt_expected_value => undef,
        lvt_is_length      => 1,
        @_,
    );
    my $data_in            = $args{data_in};
    my $expected_tag       = $args{expected_tag};
    my $expected_length    = $args{expected_length};
    my $lvt_expected_value = $args{lvt_expected_value};

    my $headache = "";

    if ( !_correct_tag( $data_in, $expected_tag ) ) {
        $headache = _extend_headache( $headache, "invalid tag" );
    }

    if ( !_correct_lvt( $data_in, $lvt_expected_value ) ) {
        $headache = _extend_headache( $headache, "invalid lvt" );
    }

    if ( $args{lvt_is_length} == 1
        && !_current_length( $data_in, _get_head_lvt( $args{data_in} ) ) )
    {
        $headache = _extend_headache( $headache, "invalid lvt length" );
    }

    if ( defined($expected_length)
        && !_current_length( $data_in, $expected_length ) )
    {
        $headache = _extend_headache("invalid static length");
    }

    return $headache;
}

sub _correct_tag {
    my ( $data_in, $tag ) = @_;

    if (   ( _get_head_ac_class($data_in) == 0 )
        && ( _get_head_tag($data_in) == $tag ) )
    {
        return 1;
    }

    if (   ( _get_head_ac_class($data_in) == 1 )
        && ( _get_head_tag($data_in) != -1 ) )
    {
        return 1;
    }

    return 0;
}

sub _correct_lvt {
    my ( $data_in, $lvt_expected_value ) = @_;

    if ( !defined $lvt_expected_value ) {
        return _get_head_lvt($data_in) != -1;
    }

    if ( _get_head_lvt($data_in) != $lvt_expected_value ) {
        return 0;
    }

    return 1;
}

sub _current_length {
    my ( $data_in, $length_expected ) = @_;

    if ( length($data_in) == $length_expected + _get_head_length($data_in) ) {
        return 1;
    }

    return 0;
}

sub _make_head {
    my ( $tag, $ac_class, $lvt, $short_lvt ) = @_;
    $short_lvt //= 0;

    my $head_tag = $tag;
    my $head_lvt = $lvt;

    if ( $tag >= EXTENDED_TAG ) {
        $head_tag = EXTENDED_TAG;
    }
    if ( $short_lvt == 0 ) {
        if ( $lvt >= LVT_FST_EXTENSION_MIN_SIZE ) {
            $head_lvt = LVT_EXTENDER_TAG;
        }
    }

    my $head =
      pack( 'C', ( $head_tag << 4 ) | ( $ac_class << 3 ) | ($head_lvt) );

    if ( $tag >= EXTENDED_TAG ) {
        $head .= pack( 'C', $tag );
    }

    if ( $short_lvt == 1 ) {
        return $head;
    }

    if ( $lvt >= LVT_TRD_EXTENSION_MIN_SIZE ) {
        $head .= pack( 'C', LVT_TRD_EXTENDER );
        $head .= pack( 'N', $lvt );
    }
    elsif ( $lvt >= LVT_SND_EXTENSION_MIN_SIZE ) {
        $head .= pack( 'C', LVT_SND_EXTENDER );
        $head .= pack( 'n', $lvt );

    }
    elsif ( $lvt >= LVT_FST_EXTENSION_MIN_SIZE ) {
        $head .= pack( 'C', $lvt );
    }

    return $head;
}

sub _get_potential_head {
    my ($data_in) = @_;

    return substr( $data_in, 0, 7 );
}

sub _get_tag_and_ac_class {

    my ( $tag_in, $modified_tag ) = @_;

    my $ac_class = 0;
    my $tag      = $tag_in;

    if ( defined $modified_tag ) {
        $ac_class = 1;
        $tag      = $modified_tag;
    }

    return ( $tag, $ac_class );
}

sub _construct_head {

    my ( $tag_in, $modified_tag, $lvt, ) = @_;

    my ( $tag, $ac_class ) =
      BACnet::DataTypes::Utils::_get_tag_and_ac_class( $tag_in, $modified_tag );

    return _make_head( $tag, $ac_class, $lvt );

}

sub _get_char_string_coding_type {
    my ($data_in) = @_;

    return unpack( 'C', substr( $data_in, _get_head_length($data_in), 1 ) );
}

sub _property_identifier_value_wrapper {
    my ($bone) = @_;
    if ( !defined $bone->{skeleton} ) {
        $bone->set_name('value');
        return BACnet::DataTypes::Bone->construct(
            dt       => 'BACnet::DataTypes::SequenceValue',
            skeleton => [$bone],
        );
    }

    return $bone;
}

sub _normalize_substitution {
    my ( $substitution, $default_substitution ) = @_;

    if ( ref($substitution) eq 'HASH' ) {
        return $substitution;
    }
    return $default_substitution;
}

1;
