#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Data::Structure::Util qw(unbless get_blessed has_circular_ref);
use Data::Dumper;

use Test::More tests => 17;

ok( 1, "we loaded fine..." );

my $obj = bless {
    key1 => [ 1, 2, 3, bless {} => 'Tagada' ],
    key2 => undef,
    key3 => {
        key31 => {},
        key32 => bless { bla => [undef] } => 'Tagada',
    },
    key5 => bless [] => 'Ponie',
} => 'Scoobidoo';
$obj->{key4} = \$obj;
$obj->{key3}->{key33} = $obj->{key3}->{key31};

ok( my $objects = get_blessed( $obj ), "Got objects" );
ok(
    $objects->[1] == $obj->{key3}->{key32}
      || $objects->[1] == $obj->{key1}->[3]
      || $objects->[1] == $obj->{key5},
    "Got object 1"
);
ok(
    $objects->[2] == $obj->{key1}->[3]
      || $objects->[2] == $obj->{key3}->{key32}
      || $objects->[2] == $obj->{key5},
    "Got object 2"
);
is( $objects->[3],               $obj, "Got top object" );
is( @{ get_blessed( undef ) },   0,    "undef" );
is( @{ get_blessed( 'hello' ) }, 0,    "hello" );
is( @{ get_blessed() },          0,    "empty list" );

is( $obj,                  unbless( $obj ), "Have unblessed obj" );
is( ref $obj,              'HASH',          "Not blessed anymore" );
is( ref $obj->{key1}->[3], 'HASH',          "Not blessed anymore" );

my $a;
my $r;
$r = bless \$r, 'Pie';
$a->[1] = $r;

my $got = get_blessed( $a );

is( scalar @$got, 1, "1 blessed thing" );
is( $got->[0], $r );
is( ref( $got->[0] ), 'Pie' );

is( $a, unbless( $a ), "Have unblessed array" );
is( $got->[0], $r );
isnt( ref( $got->[0] ), 'Pie' );
