#!/usr/bin/perl -w

use strict;

use Test::More tests => 12;

use DateTimeX::Lite qw(Arithmetic Overload);

{
    my $dt = DateTimeX::Lite->new( year => 1900, month => 12, day => 1 );

    is( "$dt", '1900-12-01T00:00:00', 'stringification overloading' );
}

{
    my $dt = DateTimeX::Lite->new( year => 2050, month => 1, day => 15,
                            hour => 20,   minute => 10, second => 10 );

    is( "$dt", '2050-01-15T20:10:10', 'stringification overloading' );

    eval { my $x = $dt + 1 };
    like( $@, qr/Cannot add 1 to a DateTimeX::Lite object/,
          'Cannot add plain scalar to a DateTimeX::Lite object' );

    eval { my $x = $dt + bless {}, 'FooBar' };
    like( $@, qr/Cannot add FooBar=HASH\([^\)]+\) to a DateTimeX::Lite object/,
          'Cannot add plain FooBar object to a DateTimeX::Lite object' );

    eval { my $x = $dt - 1 };
    like( $@, qr/Cannot subtract 1 from a DateTimeX::Lite object/,
          'Cannot subtract plain scalar from a DateTimeX::Lite object' );

    eval { my $x = $dt - bless {}, 'FooBar' };
    like( $@, qr/Cannot subtract FooBar=HASH\([^\)]+\) from a DateTimeX::Lite object/,
          'Cannot subtract plain FooBar object from a DateTimeX::Lite object' );

    eval { my $x = $dt > 1 };
    like( $@, qr/A DateTimeX::Lite object can only be compared to another DateTimeX::Lite object/,
          'Cannot compare a DateTimeX::Lite object to a scalar' );

    eval { my $x = $dt > bless {}, 'FooBar' };
    like( $@, qr/A DateTimeX::Lite object can only be compared to another DateTimeX::Lite object/,
          'Cannot compare a DateTimeX::Lite object to a FooBar object' );

    ok( ! ( $dt eq 'some string' ),
        'DateTimeX::Lite object always compares false to a string' );

    ok( $dt ne 'some string',
        'DateTimeX::Lite object always compares false to a string' );

    ok( $dt eq $dt->clone,
        'DateTimeX::Lite object is equal to a clone of itself' );

    ok( ! ( $dt ne $dt->clone ),
        'DateTimeX::Lite object is equal to a clone of itself (! ne)' );
}
