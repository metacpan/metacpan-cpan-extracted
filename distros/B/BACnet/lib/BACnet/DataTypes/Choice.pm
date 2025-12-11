#!/usr/bin/perl

package BACnet::DataTypes::Choice;

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
require BACnet::DataTypes::SequenceValue;
require BACnet::DataTypes::SequenceOfValues;
require BACnet::DataTypes::Time;
require BACnet::DataTypes::UnsignedInt;
require BACnet::DataTypes::CharString;
require BACnet::DataTypes::Choice;
require BACnet::DataTypes::DataType;

use parent 'BACnet::DataTypes::DataType';

use constant { LENGTH => 0x00 };

#choice skeleton
#tag => [dt, inner skeleton]

sub construct {
    my ( $class, $input_dt, $modified_tag ) = @_;

    my $self = {
        data => '',
        val  => $input_dt,
    };

    if ( defined $modified_tag ) {
        if ( defined $modified_tag ) {
            $self->{data} .=
              BACnet::DataTypes::Utils::_make_head( $modified_tag, 1,
                BACnet::DataTypes::Utils::OPENING_LVT, 1 );
        }
        $self->{data} .= $self->{val}->{data};
        if ( defined $modified_tag ) {
            $self->{data} .=
              BACnet::DataTypes::Utils::_make_head( $modified_tag, 1,
                BACnet::DataTypes::Utils::CLOSING_LVT, 1 );
        }
    }
    else {
        $self->{data} = $self->{val}->{data};
    }

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in, $skeleton, $wrapped ) = @_;

    my $self = bless { data => '', val => undef }, $class;

    my $context_tag = undef;
    my $head_index  = 0;

    if ( defined $wrapped
        && BACnet::DataTypes::Utils::_is_context_sequence($data_in) )
    {
        $context_tag = BACnet::DataTypes::Utils::_get_head_tag($data_in);

        if ( $context_tag == -1 ) {
            $self->{error} = "Choice: opening context lvt tag parse error";
            $self->{data}  = $data_in;
            return $self;
        }
        $head_index += BACnet::DataTypes::Utils::_get_head_length($data_in);
    }

    if ( !defined $skeleton ) {
        $self->{val} = BACnet::DataTypes::Utils::_parse_any_dt(
            substr( $data_in, $head_index ) );
    }
    else {
        my $tag = BACnet::DataTypes::Utils::_get_head_tag(
            substr( $data_in, $head_index ) );
        for my $bone (@$skeleton) {

            if ( $bone->{tag} == $tag ) {
                $self->{val} = BACnet::DataTypes::Utils::_parse_context_dt(
                    substr( $data_in, $head_index ), $bone );
            }
        }
    }

    if ( !defined $self->{val} ) {
        $self->{error} = "Choice: unknown data type tag";
        $self->{data}  = $data_in;
        return $self;
    }

    if ( defined $self->{val}->{error} ) {
        my $helper = $self->{val}->{error};
        $self->{error} = "Choice: error propagated from ($helper)";
        $self->{data}  = $data_in;
        return $self;
    }

    $head_index += length( $self->{val}->{data} );

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
            $self->{error} = "Choice: closing context lvt tag parse error";
            $self->{data}  = $data_in;
            return $self;
        }
        $head_index += BACnet::DataTypes::Utils::_get_head_length($data_in);
    }

    $self->{data} = substr( $data_in, 0, $head_index );
    return $self;
}

1;
