#!/usr/bin/perl

package BACnet::NPDU;

use strict;
use warnings;

use parent 'BACnet::BVLC';

sub construct {
    my ($class, $apdu_data) = @_;

    my $data = '';

    # Version: ASHRAE 135-1995
    $data .= pack('C', 0x01);

    # Control: bit-field
    # - 0x04 = Expecting Reply: BACnet-Confirmed-Request-PDU
    $data .= pack('C', 0x04);

    $data .= $apdu_data;

    my $self = BACnet::BVLC->construct('Original-Unicast-NPDU', $data);

    return bless $self, $class;
}

sub parse {
    my ($self, $data) = @_;

    my @data = unpack('C*', $data);

    if ($data[0] != 0x01) {
        $self->{'error'} = 'NPDU: Invalid version';
        return $self;
    }

    #if ($data[1] != 0x00) {
    #    $self->{'error'} = 'NPDU: Invalid control';
    #    return $self;
    #}

    bless $self, 'BACnet::APDU';

    $self->parse(substr $data, 2);

    return $self;
}

1;

