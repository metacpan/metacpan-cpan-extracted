package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok('Astro::UTDF') or BAIL_OUT();

i_can_ok( 'new' );
i_can_ok( 'agc' );
i_can_ok( 'azimuth' );
i_can_ok( 'clone' );
i_can_ok( 'data_interval' );
i_can_ok( 'data_validity' );
i_can_ok( 'decode' );
i_can_ok( 'doppler_count' );
i_can_ok( 'doppler_shift' );
i_can_ok( 'elevation' );
i_can_ok( 'enforce_validity' );
i_can_ok( 'factor_K' );
i_can_ok( 'factor_M' );
i_can_ok( 'frequency_band' );
i_can_ok( 'frequency_band_and_transmission_type' );
i_can_ok( 'front' );
i_can_ok( 'hex_record' );
i_can_ok( 'is_angle_valid' );
i_can_ok( 'is_angle_corrected_for_misalignment' );
i_can_ok( 'is_angle_corrected_for_refraction' );
i_can_ok( 'is_destruct_doppler' );
i_can_ok( 'is_doppler_valid' );
i_can_ok( 'is_range_corrected_for_refraction' );
i_can_ok( 'is_range_valid' );
i_can_ok( 'is_side_lobe' );
i_can_ok( 'is_last_frame' );
i_can_ok( 'measurement_time' );
i_can_ok( 'microseconds_of_year' );
i_can_ok( 'mode' );
i_can_ok( 'prior_record' );
i_can_ok( 'range' );
i_can_ok( 'range_delay' );
i_can_ok( 'range_rate' );
i_can_ok( 'raw_record' );
i_can_ok( 'rear' );
i_can_ok( 'receive_antenna_diameter_code' );
i_can_ok( 'receive_antenna_geometry_code' );
i_can_ok( 'receive_antenna_padid' );
i_can_ok( 'receive_antenna_type' );
i_can_ok( 'router' );
i_can_ok( 'seconds_of_year' );
i_can_ok( 'sic' );
i_can_ok( 'slurp' );
i_can_ok( 'tdrss_only' );
i_can_ok( 'tracker_type' );
i_can_ok( 'tracker_type_and_data_rate' );
i_can_ok( 'tracking_mode' );
i_can_ok( 'transmission_type' );
i_can_ok( 'transmit_antenna_diameter_code' );
i_can_ok( 'transmit_antenna_geometry_code' );
i_can_ok( 'transmit_antenna_padid' );
i_can_ok( 'transmit_antenna_type' );
i_can_ok( 'transmit_frequency' );
i_can_ok( 'transponder_latency' );
i_can_ok( 'vid' );
i_can_ok( 'year' );

SKIP: {
    local $@;
    my $utdf = eval { Astro::UTDF->new() };
    isa_ok( $utdf, 'Astro::UTDF' )
	or skip( 'new() did not return an Astro::UTDF', 2 );

    my $clone = eval { $utdf->clone() };
    isa_ok( $clone, 'Astro::UTDF' );
    is_deeply( $clone, $utdf, q{Clone's attributes equal original's} );

}

SKIP: {

    $ENV{DEVELOPER_TEST}
	or skip( '$ENV{DEVELOPER_TEST} is false', 1 );

    # Check that we have accounted for all methods. The arguments are
    # imports, or other things that we do not want to account for as
    # methods.
    thats_all_methods( qw{
	    FULL_CIRCLE
	    PI
	    SPEED_OF_LIGHT
	    TWO_PI
	    VERSION
	    blessed
	    can
	    carp
	    confess
	    croak
	    floor
	    isa
	    openhandle
	    timegm
	    timelocal
	    _bash_6_bytes
	    _bash_angle
	    _bash_bit
	    _bash_nybble
	    _instance
	    _static
	} );
}

done_testing;

{

    my %checked;

    sub i_can_ok {	## no critic (RequireArgUnpacking)
	my ( $method ) = @_;
	$checked{$method} = 1;
	@_ = ( Astro::UTDF->can( $method ), "Astro::UTDF->can( '$method' )" );
	goto &ok;
    }

    sub thats_all_methods {	## no critic (RequireArgUnpacking)
	my @imports = @_;
	foreach my $method ( @imports ) {
	    $checked{$method} = 1;
	}
	my @extra;
	foreach my $method ( keys %Astro::UTDF:: ) {
	    Astro::UTDF->can( $method ) or next;
	    $checked{$method} and next;
	    push @extra, $method;
	}
	foreach my $method ( sort @extra ) {
	    diag( "Extra method: $method" );
	}
	@_ = ( !@extra, 'All methods accounted for' );
	goto &ok;
    }

}

1;

# ex: set textwidth=72 :
