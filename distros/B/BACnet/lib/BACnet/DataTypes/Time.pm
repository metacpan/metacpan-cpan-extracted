#!/usr/bin/perl

package BACnet::DataTypes::Time;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

use constant { LENGTH => 0x04 };

# this did not check if the date make sense or not, because someone may want to use some weird calendar

sub construct {
    my ( $class, $hour, $minute, $second, $centisecond, $modified_tag ) = @_;

    my $self = {
        data        => '',
        hour        => $hour,
        minute      => $minute,
        second      => $second,
        centisecond => $centisecond,
    };

    $self->{data} .= BACnet::DataTypes::Utils::_construct_head(
        BACnet::DataTypes::Utils::TIME_TAG,
        $modified_tag, LENGTH );

    $self->{data} .=
      BACnet::DataTypes::Utils::_encode_int_octet_undef( $hour, 0xFF );
    $self->{data} .=
      BACnet::DataTypes::Utils::_encode_int_octet_undef( $minute, 0xFF );
    $self->{data} .=
      BACnet::DataTypes::Utils::_encode_int_octet_undef( $second, 0xFF );
    $self->{data} .=
      BACnet::DataTypes::Utils::_encode_int_octet_undef( $centisecond, 0xFF );

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $data = substr $data_in, 1;
    my $self = bless { data => $data_in, }, $class;

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in         => $data_in,
        expected_tag    => BACnet::DataTypes::Utils::TIME_TAG,
        expected_length => LENGTH,
    );

    if ( $headache ne "" ) {
        $self->{error} = "Time: $headache";
        return $self;
    }

    my $head_len = BACnet::DataTypes::Utils::_get_head_length($data_in);

    $self->{hour} =
      BACnet::DataTypes::Utils::_decode_int_octet_undef(
        substr( $data_in, $head_len, 1 ), 0xFF );
    $self->{minute} =
      BACnet::DataTypes::Utils::_decode_int_octet_undef(
        substr( $data_in, $head_len + 1, 1 ), 0xFF );
    $self->{second} =
      BACnet::DataTypes::Utils::_decode_int_octet_undef(
        substr( $data_in, $head_len + 2, 1 ), 0xFF );
    $self->{centisecond} =
      BACnet::DataTypes::Utils::_decode_int_octet_undef(
        substr( $data_in, $head_len + 3, 1 ), 0xFF );

    return $self;
}

sub val {
    my ($self) = @_;

    return return [
        $self->{hour}, $self->{minute},
        $self->{second},  $self->{centisecond}
    ];
}

sub hour {
    my ($self) = @_;

    return $self->{hour};
}

sub minute {
    my ($self) = @_;

    return $self->{minute};
}

sub second {
    my ($self) = @_;

    return $self->{second};
}

sub centisecond {
    my ($self) = @_;

    return $self->{centisecond};
}

1;
