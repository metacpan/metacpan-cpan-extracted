#!/usr/bin/perl

package BACnet::DataTypes::SequenceValue;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

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
require BACnet::DataTypes::SequenceOfValues;
require BACnet::DataTypes::Time;
require BACnet::DataTypes::UnsignedInt;
require BACnet::DataTypes::CharString;
require BACnet::DataTypes::Bone;

use BACnet::DataTypes::Enums::PropertyIdentifier;

use parent 'BACnet::DataTypes::DataType';

use constant {
    DEFAULT_SUBSTITUTION_NAME => "default",
    DEFAULT_SUBSTITUTION      =>
      $BACnet::DataTypes::Enums::PropertyIdentifier::prop_type_type,
};

sub construct {
    my ( $class, $values, $modified_tag ) = @_;

    my $self = {
        data => '',
        val  => {},
    };

    if ( defined $modified_tag ) {
        $self->{data} .= BACnet::DataTypes::Utils::_make_head( $modified_tag, 1,
            BACnet::DataTypes::Utils::OPENING_LVT, 1 );
    }

    foreach my $name_value (@$values) {
        my ( $name, $value ) = @$name_value;
        $self->{data} .= $value->data();
        %{ $self->{val} } = ( %{ $self->{val} }, $name => $value );
    }
    if ( defined $modified_tag ) {
        $self->{data} .= BACnet::DataTypes::Utils::_make_head( $modified_tag, 1,
            BACnet::DataTypes::Utils::CLOSING_LVT, 1 );
    }

    return bless $self, $class;
}

# TAG => (NAME, DATA TYPE, INNER SKELETON)
# 10 => (sth, BACnet::DataTypes::SequenceValue, { 10 => (temp, BACnet::DataTypes::Int, undef) })
#
#

sub parse {
    my ( $class, $data_in, $skeleton ) = @_;

    my $self = bless { data => '', val => {} }, $class;

    if ( ( length $data_in ) == 0 ) {
        return $self;
    }

    my $head_index  = 0;
    my $context_tag = undef;
    my $end_tag_len = 0;

    if ( BACnet::DataTypes::Utils::_is_context_sequence($data_in) ) {
        $context_tag = BACnet::DataTypes::Utils::_get_head_tag($data_in);

        if ( $context_tag == -1 ) {
            $self->{error} =
              "SequenceValue: opening context lvt tag parse error";
            return $self;
        }
        $head_index += BACnet::DataTypes::Utils::_get_head_length($data_in);
    }

    for my $bone (@$skeleton) {
        if ( length($data_in) <= $head_index ) {
            last;
        }

        if (
            BACnet::DataTypes::Utils::_is_end_of_context_sequence(
                substr( $data_in, $head_index )
            )
            && ( defined $context_tag )
          )
        {
            if (
                $context_tag != BACnet::DataTypes::Utils::_get_head_tag(
                    substr( $data_in, $head_index )
                )
              )
            {
                $self->{error} =
                  "SequenceValue: closing context lvt tag parse error";
                return $self;
            }
            else {
                $self->{data} = substr( $data_in, 0,
                    $head_index +
                      BACnet::DataTypes::Utils::_get_head_length($data_in) );
                return $self;
            }
        }

        my $dt_tag = BACnet::DataTypes::Utils::_get_head_tag(
            substr( $data_in, $head_index ) );

        if ( defined $bone->{tag} && $bone->{tag} != $dt_tag ) {
            next;
        }

        my $parsing_bone = $bone;

        if ( defined $bone->{substitution} ) {
            if (   defined $self->{val}->{ $bone->{dt} }
                && defined
                DEFAULT_SUBSTITUTION->{ $self->{val}->{ $bone->{dt} }->{val} } )
            {
                $parsing_bone =
                  BACnet::DataTypes::Utils::_property_identifier_value_wrapper(
                    DEFAULT_SUBSTITUTION->{
                        $self->{val}->{ $bone->{dt} }->{val}
                    }
                  );
            }
            else {
                $self->{error} = "SequenceValue: unknown substitution";
                return $self;
            }

        }

        my $new_dt =
          BACnet::DataTypes::Utils::_parse_context_dt(
            substr( $data_in, $head_index ),
            $parsing_bone );

        if ( !defined $new_dt ) {
            $self->{error} = "SequenceValue: unexpected parse error";
            return $self;
        }

        if ( defined $new_dt->error() ) {
            my $error = $new_dt->error();
            $self->{error} = "SequenceValue: propagated error from($error)";
            return $self;
        }

        %{ $self->{val} } = ( %{ $self->{val} }, $bone->{name} => $new_dt );
        $head_index += length( $new_dt->data() );
    }

    if ( defined $context_tag ) {
        if (
            BACnet::DataTypes::Utils::_is_end_of_context_sequence(
                substr( $data_in, $head_index )
            )
            && $context_tag == BACnet::DataTypes::Utils::_get_head_tag(
                substr( $data_in, $head_index )
            )
          )
        {
            $head_index += BACnet::DataTypes::Utils::_get_head_length(
                substr( $data_in, $head_index ) );
        }
        else {
            $self->{error} = "SequenceValue: context lvt tag parse error";
            $self->{data}  = $data_in;
            return $self;
        }
    }

    $self->{data} = substr( $data_in, 0, $head_index );
    return $self;

    return $self;

}

1;
