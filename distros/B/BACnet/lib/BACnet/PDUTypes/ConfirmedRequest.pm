#!/usr/bin/perl

package BACnet::PDUTypes::ConfirmedRequest;

use warnings;
use strict;

use bytes;

use BACnet::APDU;
use BACnet::DataTypes::SequenceValue;

use BACnet::ServiceRequestSequences::COVConfirmedNotification;
use BACnet::ServiceRequestSequences::COVUnconfirmedNotification;
use BACnet::ServiceRequestSequences::ReadProperty;
use BACnet::ServiceRequestSequences::SubscribeCOV;

require BACnet::PDUTypes::Utils;

use parent 'BACnet::PDUTypes::PDU';

our $service_choice_service_request_skeleton =
  { 1 =>
      $BACnet::ServiceRequestSequences::COVConfirmedNotification::request_skeleton,
  };

sub construct {
    my ( $class, @rest ) = @_;

    my %args = (
        invoke_id       => undef,
        service_choice  => undef,
        service_request => undef,
        flags           => 0x00,
        @rest,
    );

    my $self = {
        data            => '',
        invoke_id       => $args{invoke_id},
        service_choice  => $args{service_choice},
        service_request => $args{service_request},
        flags           => $args{flags},
        max_resp        => BACnet::APDU::MAX_RESPONSE(),
    };

    $self->{data} .= pack( 'C',
        ( $BACnet::APDU::apdu_types->{'Confirmed-Request'} << 4 ) |
          $self->{flags} );

    $self->{data} .= pack( 'C', BACnet::APDU::MAX_RESPONSE() );

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

    if ( length($data_in) < 4 ) {
        $self->{error} = "Confirmed request: too short";
        return $self;
    }

    my $offset = 0;

    $self->{flags} = unpack( 'C', substr( $data_in, $offset, 1 ) ) & 0x0f;

    if ( ( $self->{flags} & 0x08 ) != 0 ) {
        $self->{error} = "Confirmed request: segmented message";
        return $self;
    }

    $offset += 1;

    $self->{max_resp} = unpack( 'C', substr( $data_in, $offset, 1 ) ) & 0x0f;

    #in case of adding segmentation add here
    $offset += 1;

    $self->{invoke_id} = unpack( 'C', substr( $data_in, $offset, 1 ) );
    $offset += 1;

    my $service_choice = $BACnet::PDUTypes::Utils::confirmed_service_rev->{
        unpack( 'C', substr( $data_in, $offset, 1 ) ) };

    if ( !defined $service_choice ) {
        $self->{error} = "Confirmed request: unknown service choice";
        return $self;
    }

    $self->{service_choice} = $service_choice;
    $offset += 1;

    if ( !defined $skeleton ) {
        $skeleton = $service_choice_service_request_skeleton->{
            $BACnet::PDUTypes::Utils::confirmed_service->{
                $self->{service_choice}
            }
        };
    }

    if ( !defined $skeleton ) {
        $self->{error} = "Confirmed request: unknown service choice";
        return $self;
    }

    $self->{service_request} =
      BACnet::DataTypes::SequenceValue->parse( substr( $data_in, $offset ),
        $skeleton );

    if ( defined $self->{service_request}->{error} ) {
        $self->{error} = "Confirmed request: error in service request";
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

sub max_resp {
    my ($self) = @_;

    return $self->{max_resp};
}
1;
