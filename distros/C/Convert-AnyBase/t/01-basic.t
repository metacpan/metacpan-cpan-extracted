#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Convert::AnyBase;

my $hex = Convert::AnyBase->new( set => ( join '', 0 .. 9, 'a' .. 'f' ), normalize => sub { lc } );

my $crockford = Convert::AnyBase->new( set => ( join '', 0 .. 9, 'a' .. 'h', 'j', 'k', 'm', 'n', 'p' .. 't', 'v', 'w', 'x', 'y', 'z' ),
    normalize => sub { s/[oO]/0/g; s/[iIlL]/1/g; $_ },
);

is( $hex->encode( 10 ), 'a' );
is( $hex->decode( 'a' ), 10 );
is( $hex->encode( 100 ), '64' );
is( $hex->decode( '64' ), 100 );
is( $hex->encode( 1234 ), '4d2' );
is( Convert::AnyBase->decimal->encode( 10 ), '10' );
is( Convert::AnyBase->decimal->encode( 100 ), '100' );

for( split m/\n/, <<_END_ ) {
607817474 j3n3r2
136293424 41zb1g
547151162 g9sq9t
1165916803 12qwym3
137391930 430vst
1182547729 137rfrh
285987952 8gqn3g
498164611 ev2rw3
_END_
    my ( $number, $string ) = split m/\s+/;
    is( $crockford->encode( $number ), $string );
    is( $crockford->decode( $string ), $number );
    is( Convert::AnyBase->crockford->encode( $number ), $string );
    is( Convert::AnyBase->crockford->decode( $string ), $number );
}

for( split m/\n/, <<_END_ ) {
774354231 2e27b537
557270409 21374589
1004781909 3be3c155
1068288472 3facc9d8
523308145 1f310c71
1115113577 42774869
97598780 5d13d3c
1118576284 42ac1e9c
_END_
    my ( $number, $string ) = split m/\s+/;
    is( $hex->encode( $number ), $string );
    is( $hex->decode( $string ), $number );
    is( Convert::AnyBase->hex->encode( $number ), $string );
    is( Convert::AnyBase->hex->decode( $string ), $number );
}

1;
