#!/usr/bin/perl

package BACnet::PDUTypes::UnconfirmedRequest;

use warnings;
use strict;

use bytes;

use BACnet::APDU;
use BACnet::DataTypes::SequenceValue;

use BACnet::ServiceRequestSequences::COVUnconfirmedNotification;

require BACnet::PDUTypes::Utils;

use parent 'BACnet::PDUTypes::PDU';

our $service_choice_service_request_skeleton =
  { 2 =>
      $BACnet::ServiceRequestSequences::COVUnconfirmedNotification::request_skeleton,
  };

sub construct {
    my ( $class, @rest ) = @_;

    my %args = (
        service_choice  => undef,
        service_request => undef,
        @rest,
    );

    my $self = {
        data            => '',
        service_choice  => $args{service_choice},
        service_request => $args{service_request},
    };

    $self->{data} .=
      pack( 'C', ( $BACnet::APDU::apdu_types->{'Unconfirmed-Request'} << 4 ) );

    $self->{data} .= pack(
        'C',
        $BACnet::PDUTypes::Utils::unconfirmed_service->{
            $self->{service_choice}
        }
    );

    $self->{data} .= $self->{service_request}->data();

    return bless $self, $class;

}

sub parse {

    my ( $class, $data_in, $skeleton ) = @_;

    my $self = bless { data => $data_in, }, $class;

    if ( length($data_in) < 2 ) {
        $self->{error} = "Unconfirmed request: too short";
        return $self;
    }

    my $offset = 0;

    #flags should be  0000 but there is no point for check it

    $offset += 1;

    my $service_choice = $BACnet::PDUTypes::Utils::unconfirmed_service_rev->{
        unpack( 'C', substr( $data_in, $offset, 1 ) ) };

    if ( !defined $service_choice ) {
        $self->{error} = "Unconfirmed request: unknown service choice";
        return $self;
    }

    $self->{service_choice} = $service_choice;
    $offset += 1;

    if ( !defined $skeleton ) {
        $skeleton = $service_choice_service_request_skeleton->{
            $BACnet::PDUTypes::Utils::unconfirmed_service->{
                $self->{service_choice}
            }
        };
    }

    if ( !defined $skeleton ) {
        $self->{error} = "Unconfirmed Request: unknown service choice";
        return $self;
    }

    $self->{service_request} =
      BACnet::DataTypes::SequenceValue->parse( substr( $data_in, $offset ),
        $skeleton );

    if ( defined $self->{service_request}->{error} ) {
        $self->{error} = "Unconfirmed request: error in service request";
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

sub flags {
    my ($self) = @_;

    return 0;
}

1;
