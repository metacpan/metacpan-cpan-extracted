#!/usr/bin/perl

package BACnet::APDU;

use warnings;
use strict;

use BACnet::DataTypes::ObjectIdentifier;
use BACnet::DataTypes::UnsignedInt;
use BACnet::DataTypes::UnsignedInt;

use BACnet::PDUTypes::ConfirmedRequest;
use BACnet::PDUTypes::UnconfirmedRequest;
use BACnet::PDUTypes::SimpleACK;
use BACnet::PDUTypes::ComplexACK;
use BACnet::PDUTypes::Error;
use BACnet::PDUTypes::Reject;
use BACnet::PDUTypes::Abort;

use parent 'BACnet::NPDU';

use constant { MAX_RESPONSE => 0x04, };

our $apdu_types = {
    'Confirmed-Request'   => 0x0,    #Implemented
    'Unconfirmed-Request' => 0x1,    #Implemented
    'Simple-ACK'          => 0x2,    #Implemented
    'Complex-ACK'         => 0x3,    #Implemented
    'Segmented-ACK'       => 0x4,
    'Error'               => 0x5,    #Implemented
    'Reject'              => 0x6,    #Implemented
    'Abort'               => 0x7,    #Implemented
};

our $apdu_types_rev = { reverse %$apdu_types };

our $apdu_tag_type = {
    0x0 => 'BACnet::PDUTypes::ConfirmedRequest',
    0x1 => 'BACnet::PDUTypes::UnconfirmedRequest',
    0x2 => 'BACnet::PDUTypes::SimpleACK',
    0x3 => 'BACnet::PDUTypes::ComplexACK',
    0x4 => undef,
    0x5 => 'BACnet::PDUTypes::Error',
    0x6 => 'BACnet::PDUTypes::Reject',
    0x7 => 'BACnet::PDUTypes::Abort',
};

sub construct {
    my ( $class, $apdu_payload ) = @_;

    my $data = $apdu_payload->{data};

    my $self = BACnet::NPDU->construct($data);

    $self->{payload} = $apdu_payload;

    return bless $self, $class;
}

sub parse {
    my ( $self, $data ) = @_;

    my @data = unpack( 'C*', $data );

    if ( !defined $data[0] ) {
        $self->{error} = "APDU: missing apdu type";
        return $self;
    }

    my $apdu_type = $data[0] >> 4;

    my $apdu_type_to_parse = $apdu_tag_type->{$apdu_type};

    if ( !defined $apdu_type_to_parse ) {
        $self->{error} = "APDU: unknown apdu type";
        return $self;
    }

    $self->{payload} = $apdu_type_to_parse->parse($data);

    if ( defined $self->{payload}->{error} ) {
        $self->{error} =
          "APDU: propagated error($self->{payload}->{error})";
        return $self;
    }

    return $self;
}

1;
