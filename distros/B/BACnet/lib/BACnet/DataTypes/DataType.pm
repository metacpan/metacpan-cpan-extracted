#!/usr/bin/perl

package BACnet::DataTypes::DataType;

use warnings;
use strict;

use bytes;

use BACnet::DataTypes::Utils;

sub parse {
    my ( $class, $data_in ) = @_;
    my $self = bless { data => $data_in, }, $class;

    return $self;
}

sub data {
    my ($self) = @_;

    return $self->{data};
}

sub val {
    my ($self) = @_;

    return $self->{val};
}

sub error {
    my ($self) = @_;

    return $self->{error};
}

sub lvt {
    my ($self) = @_;

    return BACnet::DataTypes::Utils::_get_head_lvt( $self->{data} );
}

sub tag {
    my ($self) = @_;

    return BACnet::DataTypes::Utils::_get_head_tag( $self->{data} );
}

sub ac_class {
    my ($self) = @_;

    return BACnet::DataTypes::Utils::_get_head_ac_class( $self->{data} );
}

1;
