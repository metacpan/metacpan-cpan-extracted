#!/usr/bin/perl

package BACnet::DataTypes::Date;

use warnings;
use strict;

use BACnet::DataTypes::Utils;

use parent 'BACnet::DataTypes::DataType';

use constant { YEAR_OFFSET => 1900 };
use constant { LENGTH      => 4 };

# this did not check if the date make sense or not, because someone may want to use some weird calendar

sub construct {
    my ( $class, $year, $month, $day, $day_of_the_week, $modified_tag ) = @_;

    # $month (1-12), $day, $day_of_the_week (1-7)

    my $self = {
        data            => '',
        year            => $year,
        month           => $month,
        day             => $day,
        day_of_the_week => $day_of_the_week,
    };

    $self->{data} .= BACnet::DataTypes::Utils::_construct_head(
        BACnet::DataTypes::Utils::DATE_TAG,
        $modified_tag, LENGTH );

    if ( defined $year ) {
        $self->{data} .=
          BACnet::DataTypes::Utils::_encode_int_octet_undef( $year - YEAR_OFFSET,
            0xFF );
    }
    else {
        $self->{data} .=
          BACnet::DataTypes::Utils::_encode_int_octet_undef( $year, 0xFF );
    }

    my @date_parts = ( $month, $day, $day_of_the_week );

    for my $date_part (@date_parts) {
        $self->{data} .=
          BACnet::DataTypes::Utils::_encode_int_octet_undef( $date_part, 0xFF );
    }

    return bless $self, $class;
}

sub parse {
    my ( $class, $data_in ) = @_;

    my $data = substr $data_in, 1;
    my $self = bless { data => $data_in, }, $class;

    my $headache = BACnet::DataTypes::Utils::_correct_head(
        data_in         => $data_in,
        expected_tag    => BACnet::DataTypes::Utils::DATE_TAG,
        expected_length => LENGTH,
    );

    if ( $headache ne "" ) {
        $self->{error} = "Date: $headache";
        return $self;
    }

    my $head_len = BACnet::DataTypes::Utils::_get_head_length($data_in);

    $self->{year} =
      BACnet::DataTypes::Utils::_decode_int_octet_undef(
        substr( $data_in, $head_len, 1 ), 0xFF );
    if ( defined $self->{year} ) {
        $self->{year} =
          BACnet::DataTypes::Utils::_decode_int_octet_undef(
            substr( $data_in, $head_len, 1 ), 0xFF ) + YEAR_OFFSET;
    }

    $self->{month} =
      BACnet::DataTypes::Utils::_decode_int_octet_undef(
        substr( $data_in, $head_len + 1, 1 ), 0xFF );
    $self->{day} =
      BACnet::DataTypes::Utils::_decode_int_octet_undef(
        substr( $data_in, $head_len + 2, 1 ), 0xFF );
    $self->{day_of_the_week} =
      BACnet::DataTypes::Utils::_decode_int_octet_undef(
        substr( $data_in, $head_len + 3, 1 ), 0xFF );

    return $self;
}

sub val {
    my ($self) = @_;

    return return [
        $self->{year}, $self->{month},
        $self->{day},  $self->{day_of_the_week}
    ];
}

sub year {
    my ($self) = @_;

    return $self->{year};
}

sub month {
    my ($self) = @_;

    return $self->{month};
}

sub day {
    my ($self) = @_;

    return $self->{day};
}

sub day_of_the_week {
    my ($self) = @_;

    return $self->{day_of_the_week};
}

1;
