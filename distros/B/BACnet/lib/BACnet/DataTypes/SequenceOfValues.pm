#!/usr/bin/perl

package BACnet::DataTypes::SequenceOfValues;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

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

sub construct {
    my ( $class, $values, $modified_tag ) = @_;

    my $self = {
        data => '',
        val  => $values,
    };

    if ( defined $modified_tag ) {
        $self->{data} .= BACnet::DataTypes::Utils::_make_head( $modified_tag, 1,
            BACnet::DataTypes::Utils::OPENING_LVT, 1 );
    }

    for my $val ( @{$values} ) {
        $self->{data} .= $val->data();
    }

    if ( defined $modified_tag ) {
        $self->{data} .= BACnet::DataTypes::Utils::_make_head( $modified_tag, 1,
            BACnet::DataTypes::Utils::CLOSING_LVT, 1 );
    }

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in, $skeleton ) = @_;

    my $self = bless { data => $data_in, val => [] }, $class;

    if ( ( length $data_in ) == 0 ) {
        return $self;
    }

    my $head_index  = 0;
    my $context_tag = undef;

    if ( BACnet::DataTypes::Utils::_is_context_sequence($data_in) ) {
        $context_tag = BACnet::DataTypes::Utils::_get_head_tag($data_in);

        if ( $context_tag == -1 ) {
            $self->{error} =
              "SequenceOfValues: opening context lvt tag parse error";
            return $self;
        }
        $head_index += BACnet::DataTypes::Utils::_get_head_length($data_in);
    }

    while ( length($data_in) > $head_index ) {
        if (
            BACnet::DataTypes::Utils::_is_end_of_context_sequence(
                substr( $data_in, $head_index )
            )
          )
        {
            if (
                $context_tag != BACnet::DataTypes::Utils::_get_head_tag(
                    substr( $data_in, $head_index )
                )
              )
            {
                $self->{error} =
"SequenceOfValues: sudden closing context lvt tag parse error";
                return $self;
            }
            else {
                $self->{data} = substr( $data_in, 0,
                    $head_index +
                      BACnet::DataTypes::Utils::_get_head_length($data_in) );
                return $self;
            }
        }

        my $new_dt = BACnet::DataTypes::Utils::_parse_context_dt(
            substr( $data_in, $head_index ),
            $skeleton->[0] );

        if ( !defined $new_dt ) {
            $self->{error} = "SequenceOfValues: unexpected parse error";
            return $self;
        }

        if ( defined $new_dt->error() ) {
            my $error = $new_dt->error();
            $self->{error} = "SequenceOfValues: propagated error from($error)";
            return $self;
        }

        if ( length( $new_dt->{data} ) == 0 ) {
            $self->{error} = "SequenceOfValues: unparsable elements";
            return $self;
        }

        push( @{ $self->{val} }, $new_dt );
        $head_index += length( $new_dt->data() );
    }

    if ( defined $context_tag ) {
        $self->{error} =
          "SequenceOfValues: closing context lvt tag parse error";
    }

    return $self;

}

1;
