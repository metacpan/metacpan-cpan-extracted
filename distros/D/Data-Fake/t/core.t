use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use Data::Fake::Core;

subtest 'fake_pick' => sub {
    my %list = map { $_ => 1 } qw/one two three/;
    my $chooser = fake_pick( keys %list );
    for ( 1 .. 10 ) {
        my $got = $chooser->();
        ok( exists( $list{$got} ), "got key $got in list" );
    }

    $chooser = fake_pick( fake_int( 10, 99 ), fake_float( 0, 1 ), );
    for ( 1 .. 10 ) {
        my $got = $chooser->();
        my $re  = qr/^(?:0\.\d+|\d\d)$/;
        like( $got, $re, "fake_pick evaluated options as expected" );
    }

};

subtest 'fake_int' => sub {
    for my $min ( -1, 0 .. 2 ) {
        for my $max ( 3, 5.1, 10 ) {
            my $rand = fake_int( $min, $max );
            for ( 1 .. 5 ) {
                my $got = $rand->();
                ok( $got >= $min && $got <= $max, "random ($got) in range ($min - $max)" );
            }
        }
    }
};

subtest 'fake_float' => sub {
    for my $min ( -1.0, 0, 2.2 ) {
        for my $max ( 3, 5.1, 9.9 ) {
            my $rand = fake_float( $min, $max );
            for ( 1 .. 5 ) {
                my $got = $rand->();
                ok( $got >= $min && $got <= $max, "random ($got) in range ($min - $max)" );
            }
        }
    }
};

subtest 'fake_digits' => sub {
    for ( 1 .. 3 ) {
        my $got = fake_digits("###")->();
        like( $got, qr/^\d+$/, "digit replacement ($got)" );
    }

    my $got = fake_digits('\####')->();
    like( $got, qr/^#\d+$/, "digit replacement 1 ($got)" );

    $got = fake_digits('###-\####-\####-###')->();
    like( $got, qr/^\d{3}-#\d{3}-#\d{3}-\d{3}$/, "digit replacement 2 ($got)" );
};

subtest 'fake_template' => sub {
    for ( 1 .. 3 ) {
        my $fcn = fake_template( "%s.%s.%s.%s", map { fake_int( 1, 254 ) } 1 .. 4 );
        my $got = $fcn->();
        like( $got, qr/^\d+\.\d+\.\d+\.\d+$/, "template replacement ($got)" );
    }
    for ( 1 .. 3 ) {
        my $fcn = fake_template( '$%.2f', fake_float( 0, 10 ) );
        my $got = $fcn->();
        like( $got, qr/^\$\d\.\d\d$/, "template replacement 2 ($got)" );
    }
};

subtest 'fake_array' => sub {
    my $re = re(qr/^(?:Larry|Damian|Randall)/);

    for my $size ( 2 .. 4 ) {
        my $factory = fake_array( $size, fake_pick(qw/Larry Damian Randall/) );

        my $expected = [ map { $re } 1 .. $size ];

        for my $i ( 1 .. 3 ) {
            my $got = $factory->();
            cmp_deeply( $got, $expected, "generated array $i of size $size" );
        }
    }

    my $got = fake_array( 0, "Larry" )->();
    cmp_deeply( $got, [], "generated array of size 0 is empty" );

    $got = fake_array( 2, { first => 1 } )->();
    cmp_deeply(
        $got,
        [ { first => 1 }, { first => 1 } ],
        "generated array with constant hash structure"
    );

    $got = fake_array( 2, { name => fake_pick(qw/Larry Damian Randall/) } )->();
    cmp_deeply(
        $got,
        [ { name => $re }, { name => $re } ],
        "generated array with dynamic hash structure"
    );
};

subtest 'variable size fake_array' => sub {
    my $re = qr/^(?:Larry|Damian|Randall)/;

    for my $max_size ( 3 .. 4 ) {
        for my $min_size ( 0 .. 2 ) {
            my $factory =
              fake_array( fake_int( $min_size, $max_size ),
                fake_pick(qw/Larry Damian Randall/) );

            for my $i ( 1 .. 10 ) {
                my $got    = $factory->();
                my $length = @$got;
                ok(
                    $length >= $min_size && $length <= $max_size,
                    "var array size $length between $min_size and $max_size"
                );
                for my $item (@$got) {
                    like( $item, $re, "element value correct" );
                }
            }
        }
    }
};

subtest 'fake_hash' => sub {
    my $factory = fake_hash(
        {
            name  => fake_pick(qw/Larry Damian Randall/),
            phone => fake_hash(
                {
                    home => fake_pick( "555-1212", "555-1234" ),
                    work => fake_pick( "666-1234", "666-7777" ),
                }
            ),
            color => 'blue',
        }
    );

    my $expected = {
        name  => re(qr/^(?:Larry|Damian|Randall)/),
        phone => {
            home => re(qr/^555/),
            work => re(qr/^666/),
        },
        color => 'blue',
    };

    for my $i ( 1 .. 5 ) {
        my $got = $factory->();
        cmp_deeply( $got, $expected, "generated hash $i" );
    }

    $factory = fake_hash(
        { name => fake_pick(qw/Larry Damian Randall/) },
        fake_hash(
            {
                phone => {
                    home => fake_pick( "555-1212", "555-1234" ),
                    work => fake_pick( "666-1234", "666-7777" ),
                },
            }
        ),
        { color => 'blue' },
    );

    cmp_deeply( $factory->(), $expected, "generated hash from fragments" );
};

subtest 'fake_binomial' => sub {
    my $factory = fake_binomial( 0.999, { name => 'Joe' }, {} );
    my $result;
    for ( 1 .. 3 ) {
        my $temp = $factory->();
        if ( keys %$temp ) {
            $result ||= $temp;
        }
    }
    cmp_deeply( $result, { name => 'Joe' }, "maybe hash, likely" );

    $factory = fake_binomial( 0.001, { name => 'Joe' }, {} );
    $result = undef;
    for ( 1 .. 3 ) {
        my $temp = $factory->();
        if ( !keys %$temp ) {
            $result ||= $temp;
        }
    }
    cmp_deeply( $result, {}, "maybe hash, unlikely" );
};

subtest 'fake_weighted' => sub {
    my $factory = fake_weighted( [ 'one' => 999 ], [ 'two' => 1 ] );
    my $result;

    for ( 1 .. 3 ) {
        my $temp = $factory->();
        if ( $temp eq 'one' ) {
            $result ||= $temp;
        }
    }
    is( $result, 'one', "got most likely choice" );

    fake_weighted( [ 'one' => 2 ], [ two => 1 ], [ three => 1 ], [ four => 1 ] );
};

subtest 'fake_join' => sub {
    my $factory = fake_join( ",", ( fake_int( 1, 10 ) ) x 2 );
    my $got = $factory->();
    like( $got, qr/^\d+,\d+$/, "got joined output ($got)" );
};

done_testing;
#
# This file is part of Data-Fake
#
# This software is Copyright (c) 2015 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: ts=4 sts=4 sw=4 et tw=75:
