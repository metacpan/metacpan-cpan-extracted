#!/usr/bin/perl

package BACnet::DataTypes::Bone;

use warnings;
use strict;

use Data::Dumper;

use BACnet::DataTypes::Utils;

#bone serves as parsing tool it is not BACnet data type

# skeleton for sequences and choice is reference to array of bones

sub construct {
    my ( $class, @rest ) = @_;

    my %args = (
        tag          => undef,
        name         => undef,
        dt           => undef,
        skeleton     => undef,
        wrapped      => undef,
        substitution => undef,
        @rest,
    );

    my $self = {
        tag          => $args{tag},
        name         => $args{name},
        dt           => $args{dt},
        skeleton     => $args{skeleton},
        wrapped      => $args{wrapped},
        substitution => $args{substitution},
    };

    return bless $self, $class;
}

sub set_name {
    my ( $self, $name ) = @_;

    $self->{name} = $name;
}

1;
