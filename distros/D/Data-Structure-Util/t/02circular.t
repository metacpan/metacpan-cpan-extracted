#!/usr/bin/perl

use strict;
use warnings;
use blib;
use Data::Structure::Util qw(unbless get_blessed has_circular_ref);
use Data::Dumper;

my $WEAKEN;

eval q{ use Scalar::Util qw(weaken isweak) };
if ( !$@ and defined &Scalar::Util::weaken ) {
    $WEAKEN = 1;
}

use Test::More;

plan tests => 14 + 6 * $WEAKEN;

ok( 1, "we loaded fine..." );

my $obj = bless {
    key1 => [ 1, 2, 3, bless {} => 'Tagada' ],
    key2 => undef,
    key3 => {
        key31 => {},
        key32 => bless { bla => [] } => 'Tagada',
    },
    key5 => bless [] => 'Ponie',
} => 'Scoobidoo';
$obj->{key4} = \$obj;
$obj->{key3}->{key33} = $obj->{key3}->{key31};

my $thing = { var1 => {} };
$thing->{var2} = [ $thing->{var1}->{hello} ];
$thing->{var1}->{hello} = $thing->{var2};

my $obj2 = { key1 => [ sub { [] } ] };
$obj2->{key2} = $obj2->{key1};

my $obj3;
$obj3 = \$obj3;

my $obj4 = { key1 => $obj3 };

my @V1 = ( 1, 2, sub { } );
my $obj5 = {
    key1 => undef,
    key2 => sub { },
    key3 => \@V1,
    key4 => $obj2,
    key5 => {
        key51 => sub  { },
        key52 => \*STDERR,
        key53 => [ 0, \"hello" ],
    },
};
$obj5->{key5}->{key53}->[2] = $obj5->{key5};
$obj5->{key5}->{key54}      = $obj5->{key5}->{key53}->[2];
$obj5->{key6}               = $obj5->{key5}->{key53}->[2];
$obj5->{key5}->{key55}      = $obj5->{key5}->{key53}->[2];

my $obj6 = { key1 => undef };
$obj = $obj6;
my $V2 = [ 1, undef, \5, sub { } ];
for ( 1 .. 50 ) {
    $obj->{key2} = {};
    $obj->{key1} = $V2;
    $obj         = $obj->{key2};
}
$obj->{key3} = \$obj6;

ok( !has_circular_ref( $thing ), "Not a circular ref" );

my $ref = has_circular_ref( $obj );
ok( $ref, "Got a circular reference" );
is( $ref, $obj, "reference is correct" );

ok( !has_circular_ref( $obj2 ), "No circular reference" );
ok( has_circular_ref( $obj3 ),  "Got a circular reference" );
ok( has_circular_ref( $obj4 ),  "Got a circular reference" );
ok( has_circular_ref( $obj5 ),  "Got a circular reference" );
ok( has_circular_ref( $obj6 ),  "Got a circular reference" );
is( $obj6, has_circular_ref( $obj6 ), "Match reference" );

ok( !has_circular_ref(), "No circular reference" );
ok( !has_circular_ref( [] ), "No circular reference" );
ok( has_circular_ref( [ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\$ref ] ),
    "Has circular reference" );

if ( $WEAKEN ) {
    my $obj7 = { key1 => {} };
    $obj7->{key1}->{key11} = $obj7->{key1};
    ok( has_circular_ref( $obj7 ), "Got a circular reference" );
    weaken( $obj7->{key1}->{key11} );
    ok( isweak( $obj7->{key1}->{key11} ), "has weaken reference" );
    ok( !has_circular_ref( $obj7 ), "No more circular reference" );

    my $obj8
      = bless { key1 => bless { parent => undef, } => 'Bar', } => 'Foo';
    $obj8->{key1}->{parent} = $obj8;
    ok( has_circular_ref( $obj8 ), "Got circular" );
    my $obj81 = $obj8->{key1};
    weaken( $obj8->{key1} );
    ok( isweak( $obj8->{key1} ),    "is weak" );
    ok( !has_circular_ref( $obj8 ), "Got no circular" );

}
else {
    warn "Scalar::Util XS version not installed, some tests skipped\n";
}

my $a;
my $r;
$a->[1] = \$r;

ok( !has_circular_ref( $a ),
    "circular ref where av_fetch() returns 0 should not SEGV" );
