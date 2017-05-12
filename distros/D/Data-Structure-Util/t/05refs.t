#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Data::Structure::Util
  qw(unbless get_blessed get_refs has_circular_ref);
use Data::Dumper;

use Test::More tests => 18;

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

ok( my $objects = get_refs( $obj ), "Got references" );
is( @$objects, 9, "got all" );
my $found;
for my $ref ( @$objects ) {
    if ( $ref == $obj )                         { $found++; ok( 1 ) }
    if ( $ref == $obj->{key1} )                 { $found++; ok( 1 ) }
    if ( $ref == $obj->{key1}->[3] )            { $found++; ok( 1 ) }
    if ( $ref == $obj->{key3} )                 { $found++; ok( 1 ) }
    if ( $ref == $obj->{key3}->{key31} )        { $found++; ok( 1 ) }
    if ( $ref == $obj->{key3}->{key32} )        { $found++; ok( 1 ) }
    if ( $ref == $obj->{key3}->{key32}->{bla} ) { $found++; ok( 1 ) }
    if ( $ref == $obj->{key5} )                 { $found++; ok( 1 ) }
    if ( $ref == \$obj )                        { $found++; ok( 1 ) }
}
is( $found, @$objects, "Found " . scalar( @$objects ) );

is( @{ get_refs( undef ) },   0, "undef" );
is( @{ get_refs( 'hello' ) }, 0, "hello" );
is( @{ get_refs() },          0, "undef" );

my $a;
my $r;
$r = \$r;
$a->[1] = $r;

my $got = get_refs( $a );

is( scalar @$got, 2, "2 references" );
is( $got->[0], $r,
    "list is depth first, so first result should be the scalar" );
