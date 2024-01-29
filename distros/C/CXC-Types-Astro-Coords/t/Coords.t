#! perl

use v5.28;
use strict;
use warnings;

use Test2::V0;
use Test::TypeTiny;
use experimental 'signatures', 'postderef';

use CXC::Types::Astro::Coords -all;
use POSIX ();

sub test_type ( $type, $pass, $fail ) {

    my $name = $type->name;

    subtest $name => sub {
        for my $input ( $pass->@* ) {
            my $label = 'ARRAY' eq ref( $input ) ? join( q{, }, $input->@* ) : $input;
            should_pass( $input, $type, "pass: $label" );
        }

        for my $input ( $fail->@* ) {
            my $label = 'ARRAY' eq ref( $input ) ? join( q{, }, $input->@* ) : $input;
            should_fail( $input, $type, "fail: $label" );
        }
    };
}

subtest Degrees => sub {

    test_type( Degrees, [ 0, 359 ], [ -1, 360 ] );

    subtest 'Coerce' => sub {

        should_pass( Degrees->coerce( $_ ), Degrees, "pass: $_ (coerce)" ) for -1, 360;

        is( Degrees->coerce( -1 ),  359, 'coerce -1' );
        is( Degrees->coerce( 360 ), 0,   'coerce 360' );
    };

};

subtest 'Longitude' => sub {

    test_type( LongitudeDegrees, [ 0, 359.999 ], [ 360, -1 ] );

    test_type(
        LongitudeArray,
        [ [ 0,  0, 0 ], [ 359, 2,  8.22 ], [ 359, 59, 59.9 ], ],
        [ [ -1, 0, 0 ], [ 359, 60, 0 ],    [ 359, 59, 60 ], ] );

    test_type(
        LongitudeSexagesimal,
        [ '0d0m0s',     '359d 2m  8.22s', '359:2:8.22' ],
        [ '360d 0m 0s', '359d 60m 0s',    '359d 00m 60s', '359:2:-8.22' ],
    );

    subtest 'Coerce' => sub {
        my @LONG     = ( 359, 2, 8.22 );
        my $LONG_Deg = $LONG[0] + ( $LONG[1] + $LONG[2] / 60 ) / 60;
        my $LONG_Str = sprintf( '%dd%dm%fs', @LONG );
        is( LongitudeDegrees->coerce( \@LONG ),    $LONG_Deg, 'Degrees from Array', );
        is( LongitudeArray->coerce( $LONG_Str ),   \@LONG,    'Array from String' );
        is( LongitudeDegrees->coerce( $LONG_Str ), $LONG_Deg, 'Degrees from String' );
    };

};

subtest 'Latitude' => sub {

    test_type( LatitudeDegrees, [ -90, 90 ], [ -91, 91 ] );

    test_type(
        LatitudeArray,
        [ [ -90, 0, 0 ], [ 90, 0, 0 ], [ 89, 59, 59.9 ], [ -89, 59, 59.9 ], ],
        [ [ -91, 0, 0 ], [ 91, 0, 0 ] ] );

    test_type(
        LatitudeSexagesimal,
        [
            '-90:0:0',       '90:0:0',         '89:59:59.9', '-89:59:59.9',
            '89d 59m 59.9s', '-89d 59m 59.9s', '89 59 59.9', '-89 59 59.9',
        ],
        [ -91, 91 ] );

    subtest 'Coerce' => sub {
        my @LAT     = ( -80, 2, 8.22 );
        my $LAT_Deg = POSIX::copysign( abs( $LAT[0] ) + ( $LAT[1] + $LAT[2] / 60 ) / 60, $LAT[0] );
        my $LAT_Str = sprintf( '%dd%dm%fs', @LAT );
        is( LatitudeDegrees->coerce( \@LAT ),    $LAT_Deg, 'Degrees from Array', );
        is( LatitudeArray->coerce( $LAT_Str ),   \@LAT,    'Array from String' );
        is( LatitudeDegrees->coerce( $LAT_Str ), $LAT_Deg, 'Degrees from String' );
    };
};


subtest 'RightAscension' => sub {

    test_type( RightAscensionDegrees, [ 0, 360 ], [ 361, -1 ] );

    test_type(
        RightAscensionArray,
        [ [ 0,  0, 0 ], [ 23, 2, 8.22 ], [ 23, 59, 59.9 ], ],
        [ [ -1, 0, 0 ], [ 24, 0, 0 ],    [ 23, 60, 0 ], [ 23, 59, 60 ], ] );

    test_type(
        RightAscensionSexagesimal,
        [ '0h0m0s',
            '23h 2m  8.22s',
            '23:2:8.22' ],

        [ '24h0m0s', '24h60m0s', '24h00m60s', '24:2:-8.22' ],
    );

    subtest 'Coerce' => sub {
        my @RA     = ( 14, 2, 8.22 );
        my $RA_Deg = 15 * ( $RA[0] + ( $RA[1] + $RA[2] / 60 ) / 60 );
        my $RA_Str = sprintf( '%dh%dm%fs', @RA );
        is( RightAscensionDegrees->coerce( \@RA ),    $RA_Deg, 'Degrees from Array', );
        is( RightAscensionArray->coerce( $RA_Str ),   \@RA,    'Array from String' );
        is( RightAscensionDegrees->coerce( $RA_Str ), $RA_Deg, 'Degrees from String' );
    };

};

subtest 'Declination' => sub {

    test_type( DeclinationDegrees, [ -90, 90 ], [ -91, 91 ] );

    test_type(
        DeclinationArray,
        [ [ -90, 0, 0 ], [ 90, 0, 0 ], [ 89, 59, 59.9 ], [ -89, 59, 59.9 ], ],
        [ [ -91, 0, 0 ], [ 91, 0, 0 ] ] );

    test_type(
        DeclinationSexagesimal,
        [
            '-90:0:0',       '90:0:0',         '89:59:59.9', '-89:59:59.9',
            '89d 59m 59.9s', '-89d 59m 59.9s', '89 59 59.9', '-89 59 59.9',
        ],
        [ -91, 91 ],
    );

    subtest 'Coerce' => sub {
        my @DEC     = ( 14, 2, 8.22 );
        my $DEC_Deg = $DEC[0] + ( $DEC[1] + $DEC[2] / 60 ) / 60;
        my $DEC_Str = sprintf( '%dd%dm%fs', @DEC );
        is( DeclinationDegrees->coerce( \@DEC ),    $DEC_Deg, 'Degrees from Array', );
        is( DeclinationArray->coerce( $DEC_Str ),   \@DEC,    'Array from String' );
        is( DeclinationDegrees->coerce( $DEC_Str ), $DEC_Deg, 'Degrees from String' );
    };

};

subtest 'Sexagesimal' => sub {

    test_type(
        Sexagesimal,
        [ '0h0m0s',  '23h 2m  8.22s', '0:0:0s', '23h 2m  8.22s' ],
        [ '24h0m0s', '23h60m0s', '23h00m60s', ],
    );

    subtest 'Coerce Deg' => sub {
        my @DEC     = ( 14, 2, 8.22 );
        my $DEC_Str = sprintf( '%dd%dm%fs', @DEC );
        my $DEC_Deg = $DEC[0] + ( $DEC[1] + $DEC[2] / 60 ) / 60;

        is( SexagesimalArray->coerce( $DEC_Str ),   \@DEC,    'Array from String' );
        is( SexagesimalDegrees->coerce( \@DEC ),    $DEC_Deg, 'Degrees from Array', );
        is( SexagesimalDegrees->coerce( $DEC_Str ), $DEC_Deg, 'Degrees from String' );
    };

    subtest 'Coerce RA' => sub {
        my @RA     = ( 14, 2, 8.22 );
        my $RA_Str = sprintf( '%dh%dm%fs', @RA );
        my $RA_Deg = 15 * ( $RA[0] + ( $RA[1] + $RA[2] / 60 ) / 60 );

        is(
            SexagesimalArray->coerce( $RA_Str ),
            array {
                item 210;
                item 32;
                item float( 3.3 );
                end;
            },
            'Array from String',
        );
        is( SexagesimalDegrees->coerce( $RA_Str ), $RA_Deg, 'Degrees from String' );
    };

};

test_type( SexagesimalHMS, [ '0h0m0s', '23h 2m  8.22s' ],
    [ '24h0m0s', '23h60m0s', '23h00m60s', ], );



done_testing();
