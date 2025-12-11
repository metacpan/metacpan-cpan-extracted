#!/usr/bin/perl

package BACnet::PDUTypes::Error;

use warnings;
use strict;

use bytes;

use BACnet::APDU;
use BACnet::DataTypes::SequenceValue;

require BACnet::PDUTypes::Utils;

use BACnet::ServiceRequestSequences::ReadProperty;
use BACnet::ServiceRequestSequences::SubscribeCOV;

use parent 'BACnet::PDUTypes::PDU';

our $service_choice_service_request_skeleton = {
    5 =>
      $BACnet::ServiceRequestSequences::SubscribeCOV::negative_response_skeleton,
    12 =>
      $BACnet::ServiceRequestSequences::ReadProperty::negative_response_skeleton,
};

sub construct {
    my ( $class, @rest ) = @_;

    my %args = (
        invoke_id       => undef,
        service_choice  => undef,
        service_request => undef,
        @rest,
    );

    my $self = {
        data            => '',
        invoke_id       => $args{invoke_id},
        service_choice  => $args{service_choice},
        service_request => $args{service_request},
    };

    $self->{data} .=
      pack( 'C', ( $BACnet::APDU::apdu_types->{'Error'} << 4 ) );

    $self->{data} .= pack( 'C', $args{invoke_id} );

    $self->{data} .= pack(
        'C',
        $BACnet::PDUTypes::Utils::confirmed_service->{
            $self->{service_choice}
        }
    );

    $self->{data} .= $self->{service_request}->data();

    return bless $self, $class;

    #flags are 0000

}

sub parse {

    my ( $class, $data_in, $skeleton ) = @_;

    my $self = bless { data => $data_in, }, $class;

    if ( length($data_in) < 3 ) {
        $self->{error} = "Error: too short";
        return $self;
    }

    my $offset = 0;
    $offset += 1;

    $self->{invoke_id} = unpack( 'C', substr( $data_in, $offset, 1 ) );
    $offset += 1;

    my $service_choice = $BACnet::PDUTypes::Utils::confirmed_service_rev->{
        unpack( 'C', substr( $data_in, $offset, 1 ) ) };

    if ( !defined $service_choice ) {
        $self->{error} = "Error: unknown service choice";
        return $self;
    }

    $self->{service_choice} = $service_choice;
    $offset += 1;

    if ( !defined $skeleton ) {
        $skeleton =
          $service_choice_service_request_skeleton->{ $self->{service_choice} };
    }

    if ( !defined $skeleton ) {
        $self->{error} = "Error: unknown service choice";
        return $self;
    }

    $self->{service_request} =
      BACnet::DataTypes::SequenceValue->parse( substr( $data_in, $offset ),
        $skeleton );

    if ( defined $self->{service_request}->{error} ) {
        $self->{error} = "Error: error in service request";
    }
    return $self;
}

sub service_choice {
    my ($self) = @_;

    return $self->{service_choice};
}

sub service_request {
    my ($self) = @_;

    return $self->{service_request};
}

sub invoke_id {
    my ($self) = @_;

    return $self->{invoke_id};
}

sub flags {
    my ($self) = @_;

    return 0;
}

1;
