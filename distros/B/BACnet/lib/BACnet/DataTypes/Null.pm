#!/usr/bin/perl

package BACnet::DataTypes::Null;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

use constant { LENGTH => 0x00 };

sub construct {
    my ( $class, $modified_tag ) = @_;

    my $self = { data => '' };

    # Context Tag doc. page 378

    my $tag = (BACnet::DataTypes::Utils::NULL_TAG);

    $self->{data} .= BACnet::DataTypes::Utils::_construct_head(
        BACnet::DataTypes::Utils::NULL_TAG,
        $modified_tag, LENGTH );

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $self = bless { data => $data_in, }, $class;

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in         => $data_in,
        expected_tag    => BACnet::DataTypes::Utils::NULL_TAG,
        expected_length => LENGTH,
    );

    if ( $headache ne "" ) {
        $self->{error} = "Null: $headache";
        return $self;
    }

    return $self;
}

sub val {
    my ($self) = @_;

    return 0;    #Null returns 0 to ensure consistence among datatype methods
}

1;
