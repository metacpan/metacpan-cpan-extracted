#!/usr/bin/perl

package Utils;

use warnings;
use strict;

use Test2::V0;
use Test2::Tools::Compare;
use Data::Dumper;

require BACnet::DataTypes::BitString;
require BACnet::DataTypes::Bool;
require BACnet::DataTypes::Date;
require BACnet::DataTypes::Double;
require BACnet::DataTypes::Enum;
require BACnet::DataTypes::Int;
require BACnet::DataTypes::Null;
require BACnet::DataTypes::ObjectIdentifier;
require BACnet::DataTypes::OctetString;
require BACnet::DataTypes::Real;
require BACnet::DataTypes::Time;
require BACnet::DataTypes::UnsignedInt;
require BACnet::DataTypes::CharString;
require BACnet::DataTypes::SequenceOfValues;
require BACnet::DataTypes::SequenceValue;
require BACnet::DataTypes::DataType;
require BACnet::DataTypes::Choice;

use BACnet::PDUTypes::ConfirmedRequest;
use BACnet::PDUTypes::UnconfirmedRequest;
use BACnet::PDUTypes::SimpleACK;
use BACnet::PDUTypes::ComplexACK;
use BACnet::PDUTypes::Error;
use BACnet::PDUTypes::Reject;
use BACnet::PDUTypes::Abort;

use constant { TEST_SEED => 42 };

sub hex_data_print {
    my ( $obj, $label ) = @_;

    if ( $obj->can('data') ) {
        my $hex = unpack( 'H*', $obj->data );
        $hex =~ s/(..)/$1 /g;
        diag "$label: 0x$hex";
    }
}

sub construct_self_parse_test_dt {
    my %args = (
        class           => undef,
        modified_tag    => undef,
        value           => undef,
        expected_value  => undef,
        debug_prints    => 0,
        bit_cmp         => undef,
        array_extractor => 1,
        head_check      => 1,
        skeleton        => undef,
        wrapped         => undef,
        @_,
    );

    $args{expected_value} //= $args{value};

    my $obj_constructed;

    if ( $args{array_extractor} == 1 ) {
        $obj_constructed =
          $args{class}
          ->construct( array_extractor( $args{value} ), $args{modified_tag} );
    }
    else {
        $obj_constructed =
          $args{class}->construct( $args{value}, $args{modified_tag} );
    }

    my $obj_parsed =
      $args{class}
      ->parse( $obj_constructed->data, $args{skeleton}, $args{wrapped} );

    if ( $args{debug_prints} ) {
        hex_data_print( $obj_constructed, "constructed data:" );
        print "constructed: ", Dumper($obj_constructed), "\n";
        hex_data_print( $obj_parsed, "parsed data:" );
        print "parsed: ", Dumper($obj_parsed), "\n";
    }

    ok $obj_parsed->isa( $args{class} ), "object is a $args{class}";

    is $obj_parsed->data, $obj_constructed->data,
      'parsed and constructed data match';
    is $obj_parsed->{error}, U(), 'no error';

    is $obj_parsed->val, $obj_constructed->val,
      'parsed and constructed value match';

    my $helper = array_extractor( $args{value} );

    is $obj_parsed, $obj_constructed, "parsed and constructed object match";

    if ( $args{head_check} == 1 ) {
        is $obj_parsed->lvt, $obj_constructed->lvt,
          'parsed and constructed lvt match';
        is $obj_parsed->tag, $obj_constructed->tag,
          'parsed and constructed tag match';
        is $obj_parsed->ac_class, $obj_constructed->ac_class,
          'parsed and constructed ac_class match';
    }

    if ( defined $args{bit_cmp} ) {
        is $obj_parsed->data, $args{bit_cmp},
          "object data matches exact given bits";
    }

    return ( $obj_constructed, $obj_parsed );
}

sub construct_self_parse_test_date {

    my %args = (
        class           => undef,
        modified_tag    => undef,
        year            => undef,
        month           => undef,
        day             => undef,
        day_of_the_week => undef,
        debug_prints    => 0,
        bit_cmp         => undef,
        @_,
    );

    my ( $obj_constructed, $obj_parsed ) = construct_self_parse_test_dt(
        class        => $args{class},
        modified_tag => $args{modified_tag},
        value        =>
          [ $args{year}, $args{month}, $args{day}, $args{day_of_the_week} ],
        debug_prints => $args{debug_prints},
        bit_cmp      => $args{bit_cmp},
    );

    is $obj_parsed->year,  $args{year},  'parse year correct';
    is $obj_parsed->month, $args{month}, 'parse month correct';
    is $obj_parsed->day,   $args{day},   'parse day correct';
    is $obj_parsed->day_of_the_week, $args{day_of_the_week},
      'parse day_of_the_week correct';
}

sub construct_self_parse_test_time {

    my %args = (
        class        => undef,
        modified_tag => undef,
        hour         => undef,
        minute       => undef,
        second       => undef,
        centisecond  => undef,
        debug_prints => 0,
        bit_cmp      => undef,
        @_,
    );

    my ( $obj_constructed, $obj_parsed ) = construct_self_parse_test_dt(
        class        => $args{class},
        modified_tag => $args{modified_tag},
        value        =>
          [ $args{hour}, $args{minute}, $args{second}, $args{centisecond} ],
        debug_prints => $args{debug_prints},
        bit_cmp      => $args{bit_cmp},
    );

    is $obj_parsed->hour,   $args{hour},   'parse hour correct';
    is $obj_parsed->minute, $args{minute}, 'parse minute correct';
    is $obj_parsed->second, $args{second}, 'parse second correct';
    is $obj_parsed->centisecond, $args{centisecond},
      'parse centisecond correct';

}

sub construct_self_parse_test_object_identifier {

    my %args = (
        class        => undef,
        modified_tag => undef,
        type         => undef,
        instance     => undef,
        debug_prints => 0,
        bit_cmp      => undef,
        @_,
    );

    my ( $obj_constructed, $obj_parsed ) = construct_self_parse_test_dt(
        class        => $args{class},
        modified_tag => $args{modified_tag},
        value        => [ $args{type}, $args{instance} ],
        debug_prints => $args{debug_prints},
        bit_cmp      => $args{bit_cmp},
    );

    is $obj_parsed->type,     $args{type},     'parse type correct';
    is $obj_parsed->instance, $args{instance}, 'parse instance correct';

}

sub construct_self_parse_test_char_string {

    my %args = (
        class          => undef,
        modified_tag   => undef,
        char_string    => undef,
        coding_type    => undef,
        debug_prints   => 0,
        bit_cmp        => undef,
        expected_value => undef,
        @_,
    );

    my ( $obj_constructed, $obj_parsed ) = construct_self_parse_test_dt(
        class          => $args{class},
        modified_tag   => $args{modified_tag},
        value          => [ $args{char_string}, $args{coding_type} ],
        debug_prints   => $args{debug_prints},
        bit_cmp        => $args{bit_cmp},
        expected_value => $args{expected_value},
    );

    is $obj_parsed->coding_type, $args{coding_type},
      'parse coding type correct';
}

sub array_extractor {
    my ($var) = @_;

    if ( ref $var eq 'ARRAY' ) {
        return @$var;
    }

    return $var;
}

sub rng {
    my ($seed) = @_;
    my $a      = 1664525;
    my $c      = 1013904223;
    my $m      = 2**32;

    return ( $a * $seed + $c ) % $m;
}

sub rng_bit_string {
    my ( $seed, $length ) = @_;
    my $rn = $seed;

    my $output = '';

    for ( 1 .. $length ) {
        $rn = rng($rn);
        my $bit = ( $rn & 1 );
        $output .= $bit;
    }

    return $output;
}

sub construct_self_parse_test_pdu {
    my %args = (
        constructor_args => undef,
        class            => undef,
        debug_prints     => 0,
        skeleton         => undef,
        @_,
    );

    my $obj_constructed =
      $args{class}->construct( %{ $args{constructor_args} } );

    my $obj_parsed =
      $args{class}->parse( $obj_constructed->data(), $args{skeleton} );

    if ( $args{debug_prints} ) {
        hex_data_print( $obj_constructed, "constructed data:" );
        print "constructed: ", Dumper($obj_constructed), "\n";
        hex_data_print( $obj_parsed, "parsed data:" );
        print "parsed: ", Dumper($obj_parsed), "\n";
    }

    ok $obj_parsed->isa( $args{class} ), "object is a $args{class}";

    is $obj_parsed->data, $obj_constructed->data,
      'parsed and constructed data match';

    is $obj_parsed->flags, $obj_constructed->flags,
      'parsed and constructed data match';
    is $obj_parsed->{error}, U(), 'no error';

    is $obj_parsed, $obj_constructed, "parsed and constructed object match";

    return ( $obj_constructed, $obj_parsed );
}

sub construct_self_parse_test_unconfirmed_request {
    my %args = (
        constructor_args => undef,
        class            => undef,
        debug_prints     => 0,
        skeleton         => undef,
        @_,
    );

    my ( $obj_parsed, $obj_constructed ) = construct_self_parse_test_pdu(%args);

    is $obj_parsed->service_choice, $obj_constructed->service_choice,
      'parsed and constructed service choice match';

    is $obj_parsed->service_request, $obj_constructed->service_request,
      'parsed and constructed service request match';

    return ( $obj_constructed, $obj_parsed );
}

sub construct_self_parse_test_confirmed_request {
    my %args = (
        constructor_args => undef,
        class            => undef,
        debug_prints     => 0,
        skeleton         => undef,
        @_,
    );

    my ( $obj_parsed, $obj_constructed ) =
      construct_self_parse_test_unconfirmed_request(%args);

    is $obj_parsed->invoke_id, $obj_constructed->invoke_id,
      'parsed and invoke id choice match';

    return ( $obj_constructed, $obj_parsed );
}

sub construct_self_parse_test_simple_ack {
    my %args = (
        constructor_args => undef,
        class            => undef,
        debug_prints     => 0,
        skeleton         => undef,
        @_,
    );

    my ( $obj_parsed, $obj_constructed ) = construct_self_parse_test_pdu(%args);

    is $obj_parsed->service_choice, $obj_constructed->service_choice,
      'parsed and constructed service choice match';

    is $obj_parsed->invoke_id, $obj_constructed->invoke_id,
      'parsed and invoke id choice match';

    return ( $obj_constructed, $obj_parsed );
}

sub construct_self_parse_test_complex_ack {
    my %args = (
        constructor_args => undef,
        class            => undef,
        debug_prints     => 0,
        skeleton         => undef,
        @_,
    );

    my ( $obj_parsed, $obj_constructed ) =
      construct_self_parse_test_simple_ack(%args);

    is $obj_parsed->service_request, $obj_constructed->service_request,
      'parsed and constructed service request match';

    return ( $obj_constructed, $obj_parsed );
}

sub construct_self_parse_test_error {
    my %args = (
        constructor_args => undef,
        class            => undef,
        debug_prints     => 0,
        skeleton         => undef,
        @_,
    );

    my ( $obj_parsed, $obj_constructed ) =
      construct_self_parse_test_simple_ack(%args);

    is $obj_parsed->service_request, $obj_constructed->service_request,
      'parsed and constructed service request match';

    return ( $obj_constructed, $obj_parsed );
}

sub construct_self_parse_test_abort {
    my %args = (
        constructor_args => undef,
        class            => undef,
        debug_prints     => 0,
        @_,
    );

    my ( $obj_parsed, $obj_constructed ) =
      construct_self_parse_test_simple_ack(%args);

    return ( $obj_constructed, $obj_parsed );
}

sub construct_self_parse_test_reject {
    my %args = (
        constructor_args => undef,
        class            => undef,
        debug_prints     => 0,
        @_,
    );

    my ( $obj_parsed, $obj_constructed ) =
      construct_self_parse_test_simple_ack(%args);

    return ( $obj_constructed, $obj_parsed );
}

sub check_if_hash {
    my ($var) = @_;

    if ( ref($var) eq 'HASH' ) {
        warn "Je to hashref (odkaz na hash)\n";
    }
    else {
        warn "Neni to hashref\n";
    }
}

sub service_request_test {
    my %args = (
        service_request => undef,
        skeleton        => undef,
        debug_prints    => 0,
        @_,
    );

    my $obj_constructed = $args{service_request};

    my $obj_parsed =
      BACnet::DataTypes::SequenceValue->parse( $obj_constructed->data(),
        $args{skeleton} );

    if ( $args{debug_prints} ) {
        hex_data_print( $obj_constructed, "constructed data:" );
        print "constructed: ", Dumper($obj_constructed), "\n";
        hex_data_print( $obj_parsed, "parsed data:" );
        print "parsed: ", Dumper($obj_parsed), "\n";
    }

    is $obj_parsed->data, $obj_constructed->data,
      'parsed and constructed data match';

    is $obj_parsed->{error}, U(), 'no error';

    is $obj_parsed, $obj_constructed, "parsed and constructed object match";

    return ( $obj_constructed, $obj_parsed );
}

1;
