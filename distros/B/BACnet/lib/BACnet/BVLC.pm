#!/usr/bin/perl

package BACnet::BVLC;

use warnings;
use strict;

use Switch;

use feature qw(switch);

sub construct {
    my ($class, $function, $data) = @_;

    my $self = {
        'data' => '',
    };
    
    # Type: BACnet/IP (Annex J)
    $self->{'data'} .= pack('C', 0x81);

    # Function
    switch ($function) {
        case 'Original-Unicast-NPDU' {
            $self->{'data'} .= pack('C', 0x0a);
        }
    }

    # BVLC-Length
    $self->{'data'} .= pack('n', (length $data) + 4);

    $self->{'data'} .= $data;

    return bless $self, $class;
}

sub parse {
    my ($class, $data) = @_;

    my $self = bless {
        'data' => $data,
    }, $class;

    my @data = unpack('C*', $data);

    if ($data[0] != 0x81) {
        $self->{'error'} = 'BVLC: invalid type';
        return $self;
    }

    if ($data[1] != 0x0a) {
        $self->{'error'} = 'BVLC: function is not Original-Unicast-NPDU';
        return $self;
    }

    bless $self, 'BACnet::NPDU';

    $self->parse(substr $data, 4);

    return $self;
}

sub data {
    my ($self) = shift;

    return $self->{'data'};
}

sub dump {
    my ($self) = shift;

    return join ' ', unpack('(H2)*', $self->{'data'});
}

1;

