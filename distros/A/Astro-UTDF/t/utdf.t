package main;

use strict;
use warnings;

use lib qw{ inc };
use Astro::UTDF::Test;
use Astro::UTDF;

plan( tests => 131 );

round_trip( agc => 10000 );
round_trip( azimuth => '1.00000000', { sprintf => '%.8f' } );
round_trip( data_interval => 1 );
round_trip( data_interval => 0.5 );
round_trip( data_validity => 7 );
round_trip( doppler_count => 123456789 );
round_trip( elevation => '1.00000000', { sprintf => '%.8f' } );
round_trip( frequency_band => 3 );
round_trip( frequency_band_and_transmission_type => 68 );
round_trip( is_angle_valid => 1 );
round_trip( is_angle_corrected_for_misalignment => 0 );
round_trip( is_angle_corrected_for_refraction => 1 );
round_trip( is_destruct_doppler => 0 );
round_trip( is_doppler_valid => 0 );
round_trip( is_range_corrected_for_refraction => 1 );
round_trip( is_range_valid => 1 );
round_trip( is_side_lobe => 0 );
round_trip( is_last_frame => 1 );
round_trip( measurement_time => 1238544000 );	# 01-Apr-2009 00:00:00
round_trip( microseconds_of_year => 314159 );
round_trip( mode => 12 );
round_trip( range_delay => 9876543210 );
round_trip( receive_antenna_diameter_code => 2 );
round_trip( receive_antenna_geometry_code => 3 );
round_trip( receive_antenna_padid => 42 );
round_trip( receive_antenna_type => 65 );
round_trip( router => '??' );
round_trip( seconds_of_year => 9999999 );
round_trip( sic => 86 );
round_trip( tdrss_only => 'Hello, world!' . pack 'H*', '0000000000' );
round_trip( tracker_type => 9 );
round_trip( tracker_type_and_data_rate => 2 );
round_trip( tracking_mode => 1 );
round_trip( transmission_type => 10 );
round_trip( transmit_antenna_diameter_code => 2 );
round_trip( transmit_antenna_geometry_code => 3 );
round_trip( transmit_antenna_padid => 42 );
round_trip( transmit_antenna_type => 65 );
round_trip( transmit_frequency => 2048000000 );
round_trip( vid => 99 );
round_trip( year => 8 );

my $file = 't/data.utd';

## my ( $prior, $utdf ) = Astro::UTDF->slurp( $file );
my ( undef, $utdf ) = Astro::UTDF->slurp( $file );

returns( $utdf, agc => 1234, 'agc' );
returns( $utdf, { sprintf => '%.9f' },
    azimuth => '5.852690027', 'azimuth' );
returns( $utdf, data_interval => 1, 'data_interval' );
returns( $utdf, data_validity => 7, 'data_validity' );
decode ( $utdf, data_validity => '0x07', 'decode data_validity' );
decode ( $utdf, frequency_band => 'S-band', 'decode frequency_band' );
# Note that perldoc -f localtime says that the string returned in
# scalar context is _not_ locale-dependant.
decode ( $utdf, measurement_time => 'Fri Mar 19 01:01:31 2010',
    'decode measurement_time' );
decode ( $utdf, mode => '0x0000', 'decode mode' );
decode ( $utdf, raw_record =>
    '0d0a0141410a00560063006591eb00000000ee75c57726d95aba00002ae62c1b00001bc09df104d20c380d40402a402a000007341001000000000000000000000000000000000000040f0f',
    'decode raw_record' );
decode ( $utdf, receive_antenna_diameter_code => '12 meters',
    'decode receive_antenna_diameter_code' );
decode ( $utdf, router => 'AA', 'decode router' );
decode ( $utdf, tracking_mode => 'autotrack', 'decode tracking_mode' );
decode ( $utdf, receive_antenna_geometry_code => 'az-el',
    'decode receive_antenna_geometry_code' );
decode ( $utdf, transmission_type => 'RT (real time)',
    'decode transmission_type' );
decode ( $utdf, transmit_antenna_diameter_code => '12 meters',
    'decode transmit_antenna_diameter_code' );
decode ( $utdf, transmit_antenna_geometry_code => 'az-el',
    'decode transmit_antenna_geometry_code' );
returns( $utdf, doppler_count => 465608177, 'doppler_count' );
returns( $utdf, { sprintf => '%.3f' },
    doppler_shift => '25608.177', 'doppler_shift' );
returns( $utdf, { sprintf => '%0.9f' },
    elevation => '0.953498911', 'elevation' );
returns( $utdf, { sprintf => '%.8f' }, factor_K => 1.08597285, 'factor_K' );
returns( $utdf, factor_M => 1000, 'factor_M' );
returns( $utdf, frequency_band => 3, 'frequency_band' );
returns( $utdf, frequency_band_and_transmission_type => 52,
    'frequency_band_and_transmission_type' );
hexify ( $utdf, front => '0d0a01', 'front' );
returns( $utdf, hex_record =>
    '0d0a0141410a00560063006591eb00000000ee75c57726d95aba00002ae62c1b00001bc09df104d20c380d40402a402a000007341001000000000000000000000000000000000000040f0f',
    'hex_record' );
returns( $utdf, is_angle_valid => 1, 'is_angle_valid' );
returns( $utdf, is_angle_corrected_for_misalignment => 0,
    'is_angle_corrected_for_misalignment' );
returns( $utdf, is_angle_corrected_for_refraction => 0,
    'is_angle_corrected_for_refraction' );
returns( $utdf, is_destruct_doppler => 0, 'is_destruct_doppler' );
returns( $utdf, is_doppler_valid => 1, 'is_doppler_valid' );
returns( $utdf, is_range_corrected_for_refraction => 0,
    'is_range_corrected_for_refraction' );
returns( $utdf, is_range_valid => 1, 'is_range_valid' );
returns( $utdf, is_side_lobe => 0, 'is_side_lobe' );
returns( $utdf, is_last_frame => 0, 'is_last_frame' );
returns( $utdf, measurement_time => 1268960491, 'measurement_time' );
returns( $utdf, microseconds_of_year => 0, 'microseconds_of_year' );
returns( $utdf, mode => 0, 'mode' );
returns( $utdf, { sprintf => '%.5f' },
    range => '421.42367', 'range' );
returns( $utdf, { sprintf => '%.10f' },
    range_rate => '-1.7242353358', 'range_rate' );
returns( $utdf, { sprintf => '%.5f' },
    range_delay => '2811436.10547', 'range_delay' );
hexify ( $utdf, rear => '040f0f', 'rear' );
returns( $utdf, receive_antenna_padid => 42, 'receive_antenna_padid' );
returns( $utdf, receive_antenna_diameter_code => 4,
    'receive_antenna_diameter_code' );
returns( $utdf, receive_antenna_geometry_code => 0,
    'receive_antenna_geometry_code' );
returns( $utdf, receive_antenna_type => 64, 'receive_antenna_type' );
returns( $utdf, router => 'AA', 'router' );
returns( $utdf, seconds_of_year => 6656491, 'seconds_of_year' );
returns( $utdf, sic => 86, 'sic' );
hexify ( $utdf, tdrss_only => '000000000000000000000000000000000000',
    'tdrss_only' );
returns( $utdf, tracker_type => 1, 'tracker_type' );
returns( $utdf, tracker_type_and_data_rate => 4097,
    'tracker_type_and_data_rate' );
returns( $utdf, tracking_mode => 0, 'tracking_mode' );
returns( $utdf, transmission_type => 4, 'transmission_type' );
returns( $utdf, transmit_antenna_diameter_code => 4,
    'transmit_antenna_diameter_code' );
returns( $utdf, transmit_antenna_geometry_code => 0,
    'transmit_antenna_geometry_code' );
returns( $utdf, transmit_antenna_padid => 42, 'transmit_antenna_padid' );
returns( $utdf, transmit_antenna_type => 64, 'transmit_antenna_type' );
returns( $utdf, transmit_frequency => 2050000000, 'transmit_frequency' );
returns( $utdf, transponder_latency => 0, 'transponder_latency' );
returns( $utdf, vid => 99, 'vid (Vehicle ID)' );
returns( $utdf, year => 10, 'year' );

SKIP: {

    local $@;

    my $utdf = Astro::UTDF->new(
	doppler_count => 44000000000,
	is_doppler_valid => 1,
	enforce_validity => 0,
	transmit_frequency => 2050000000,
    );
    my $clone;

    ok( eval { $clone = $utdf->clone() },	## no critic (RequireCheckingReturnValueOfEval)
	'Clone our object' )
	or skip( "Failed to clone object", 10 );

    ok( eval { $clone->enforce_validity( 1 ) },	## no critic (RequireCheckingReturnValueOfEval)
	'Set enforce_validity' )
	or skip( "Failed to set enforce_validity", 9 );

    ok( eval { $clone->enforce_validity() },	## no critic (RequireCheckingReturnValueOfEval)
	'See if enforce_validity is set' )
	or skip( "Failed to set enforce_validity", 8 );

    returns( $clone, azimuth => undef, 'azimuth (invalid)' );
    returns( $clone, doppler_count => 44000000000, 'doppler_count (valid)' );
    returns( $clone, elevation => undef, 'elevation (invalid)' );
    returns( $clone, range_delay => undef, 'range_delay (invalid)' );

    $clone->factor_M( 100 );
    returns( $clone, factor_M => 100, 'factor_M changed to 100' );
    $clone->factor_M( undef );
    returns( $clone, factor_M => 1000, 'factor_M defaulted to 1000' );

    $clone->factor_K( 1 );
    returns( $clone, factor_K => 1, 'factor_K changed to 1' );
    $clone->factor_K( undef );
    returns( $utdf, { sprintf => '%.8f' }, factor_K => 1.08597285,
	'factor_K defaulted to 240/221' );

}

{
    my ( $prior, $utdf ) = Astro::UTDF->slurp( file => $file,
	enforce_validity => 1, is_range_valid => 0 );
    ok( eval { $utdf->enforce_validity() },	## no critic (RequireCheckingReturnValueOfEval)
	'Can pass attributes to slurp()' );

    my $other = $utdf->new();
    isa_ok( $other, 'Astro::UTDF', 'Can call new() on an object' );
    ok( ! $other->enforce_validity(), '$utdf->new() is not $utdf->clone()' );

    fails( 'Astro::UTDF', 'new', fubar => 0, 'Method fubar() not found',
	'new() can not set value of fubar' );

    fails( $utdf, data_interval => -1,
	'Negative data interval invalid', 'Negative data_interval' );

    fails( $utdf, doppler_shift => 2000,
	'doppler_shift() may not be used as a mutator',
	'doppler_shift() is not a mutator' );

    returns( $prior, doppler_shift => undef,
	'no doppler_shift() without prior_record()' );

    $utdf->enforce_validity( 1 );
    returns( $utdf, { sprintf => '%.3f' }, doppler_shift => '25608.177',
	'Doppler shift with enforce_validity()' );

    $prior->prior_record( $utdf );
    returns( $prior, { sprintf => '%.3f' }, doppler_shift =>
	'25608.177', 'Doppler shift with records reversed' );

    fails( $prior, prior_record => 42,
	'Prior record must be undef or an Astro::UTDF object',
	'prior_record() validation' );

    $prior->prior_record( undef );

    fails( $utdf, range => 42,
	'range() may not be used as a mutator',
	'range() can not be a mutator' );

    returns( $utdf, range => undef, 'No range with enforce_validity()' );

    fails( $utdf, range_rate => 42,
	'range_rate() may not be used as a mutator',
	'range_rate() can not be a mutator' );

    returns( $prior, range_rate => undef,
	'No range_rate() without a prior_record()' );

    fails( $utdf, raw_record => 'fubar',
	'Invalid raw record', 'Raw record not 75 bytes long' );

    fails( 'Astro::UTDF', 'slurp', 'File not specified',
	'slurp() requires a file' );

    fails( 'Astro::UTDF', slurp => 't/fubar.utd',
	't/fubar.utd not found',
	'Can not slurp a non-existent file' );

    fails( 'Astro::UTDF', slurp => 't',
	't not a normal file',
	'Can not slurp a non-normal file' );

}

1;

# ex: set textwidth=72 :
