#!/usr/bin/perl

package BACnet::PDUTypes::PDU;

use warnings;
use strict;

use bytes;

use BACnet::DataTypes::Utils;

sub data {
    my ($self) = @_;

    return $self->{data};
}

sub flags {
    my ($self) = @_;

    return $self->{flags};
}

1;
