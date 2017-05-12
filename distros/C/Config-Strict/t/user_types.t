#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 31;

use Config::Strict qw(register_types);
use Declare::Constraints::Simple -All;

# Failure
eval { Config::Strict->register_types( 'Enum' => IsOneOf ) };
like( $@ => qr/already a registered type/i, 'already registered' );
eval { Config::Strict->register_types( 'Blah' => 'Foo' ) };
like( $@ => qr/not a coderef/i, 'bad profile' );

# Okay
Config::Strict->register_types(
    'Private'        => Matches( qr/^_/ ),
    'ArrayOfAllCaps' => IsArrayRef( Matches( qr/^[A-Z]+$/ ) ),
    'LessThan8Chars' => HasLength( 1, 8 ),
    'Size'           => IsOneOf( qw(small medium large) ),
    'PosNum'         => sub { $_[ 0 ] > 0 },
);
my $config = Config::Strict->new( {
        params => {
            Private        => 'myvar',
            ArrayOfAllCaps => 'caps',
            LessThan8Chars => [ qw( short1 short2 ) ],
            Size           => 'size',
            PosNum         => 'posn'
        }
    }
);

for ( qw( myvar caps short1 short2 size posn ) ) {
    ok( $config->param_exists( $_ ),  "$_ exists" );
    ok( !$config->param_is_set( $_ ), "$_ unset" );
}

# PosNum (bare sub)
eval { $config->set( 'posn' => 0 ); };
like( $@ => qr/PosNum constraint/, 'PosNum' );
ok( $config->set( 'posn' => 0.1 ), 'PosNum' );
is( $config->get( 'posn' ) => 0.1, 'PosNum' );
#print Dumper $config;

# Private
eval { $config->set( 'myvar' => 'bad' ); };
like( $@ => qr/regex does not match/i, 'private' );
ok( $config->set( 'myvar' => '_ok' ), 'Private' );
is( $config->get( 'myvar' ) => '_ok', 'Private' );

# Caps Array
eval { $config->set( 'caps' => [ 'NOT', 'GOOd' ] ); };
like( $@ => qr/regex does not match/i, 'caps' );
ok( $config->set( 'caps' => [ 'IZ', 'OK' ] ), 'caps' );
is_deeply( $config->get( 'caps' ) => [ 'IZ', 'OK' ], 'caps' );

# Short values
eval { $config->set( 'short1' => '' ) };
like( $@ => qr/value too short/i, 'short1' );
eval { $config->set( 'short1' => '123456789' ) };
like( $@ => qr/value too long/i, 'short1' );
ok( $config->set( 'short1' => '12345678' ), 'short1' );
ok( $config->set( 'short2' => '1' ),        'short2' );
is_deeply(
    [ $config->get( qw( short1 short2 ) ) ] => [ '12345678', '1' ],
    'shorts'
);

# Size
eval { $config->set( 'size' => 'Small' ) };
like( $@ => qr/no value matches/i, 'size' );
ok( $config->set( 'size' => 'small' ), 'size' );
is( $config->get( 'size' ) => 'small', 'size' );
