#!/usr/bin/perl

package BACnet::DataTypes::Bool;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

use constant {
    CONTEXT_LENGTH => 0x01,
    TRUE           => 1,
    FALSE          => 0,
};

sub construct {
    my ( $class, $bool_in, $modified_tag ) = @_;

    $bool_in = BACnet::DataTypes::Utils::_normalize_bool($bool_in);

    my $self = {
        data => '',
        val  => $bool_in
    };

    if ( defined $modified_tag ) {
        $self->{data} .=
          BACnet::DataTypes::Utils::_make_head( $modified_tag, 1,
            CONTEXT_LENGTH );
        $self->{data} .= pack( 'C', $bool_in );
    }
    else {
        $self->{data} .=
          BACnet::DataTypes::Utils::_make_head(
            BACnet::DataTypes::Utils::BOOL_TAG,
            0, $bool_in );
    }

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in }, $class;

    my @bytes = unpack( "C*", $data_in );

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in       => $data_in,
        expected_tag  => BACnet::DataTypes::Utils::BOOL_TAG,
        lvt_is_length => 0,
    );

    if ( $headache ne "" ) {
        $self->{error} = "Application Bool: $headache";
        return $self;
    }

    if ( BACnet::DataTypes::Utils::_get_head_ac_class($data_in) == 1 ) {

        if (
            !BACnet::DataTypes::Utils::_current_length(
                $data_in, BACnet::DataTypes::Utils::_get_head_lvt($data_in)
            )
          )
        {
            $self->{error} = "Application Bool: invalid lvt length";
            return $self;
        }

        $self->{val} =
          $bytes[ BACnet::DataTypes::Utils::_get_head_length($data_in) ];
    }
    else {
        $self->{val} = $bytes[0] & 0x07;
    }

    return $self;
}

1;
