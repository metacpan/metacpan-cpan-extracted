#!/usr/bin/perl

package BACnet::PDUTypes::Reject;

use warnings;
use strict;

use bytes;

use BACnet::APDU;

require BACnet::PDUTypes::Utils;

use parent 'BACnet::PDUTypes::PDU';

sub construct {
    my ( $class, @rest ) = @_;

    my %args = (
        invoke_id      => undef,
        service_choice => undef,
        @rest,
    );

    my $self = {
        data           => '',
        invoke_id      => $args{invoke_id},
        service_choice => $args{service_choice},
    };

    $self->{data} .=
      pack( 'C', ( $BACnet::APDU::apdu_types->{'Reject'} << 4 ) );

    $self->{data} .= pack( 'C', $args{invoke_id} );

    $self->{data} .= pack( 'C',
        $BACnet::PDUTypes::Utils::reject_reason->{ $self->{service_choice} } );

    return bless $self, $class;

    #flags are 0000

}

sub parse {

    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;

    if ( length($data_in) < 3 ) {
        $self->{error} = "Reject: too short";
        return $self;
    }

    my $offset = 0;
    $offset += 1;

    $self->{invoke_id} = unpack( 'C', substr( $data_in, $offset, 1 ) );
    $offset += 1;

    my $service_choice = $BACnet::PDUTypes::Utils::reject_reason_rev->{
        unpack( 'C', substr( $data_in, $offset, 1 ) ) };

    if ( !defined $service_choice ) {
        $self->{error} = "Reject: unknown service choice";
        return $self;
    }

    $self->{service_choice} = $service_choice;

    return $self;
}

sub service_choice {
    my ($self) = @_;

    return $self->{service_choice};
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
