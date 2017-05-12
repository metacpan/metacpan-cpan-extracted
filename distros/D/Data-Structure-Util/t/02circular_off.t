#!/usr/bin/perl

use strict;
use warnings;
use blib;
use Data::Structure::Util qw(has_circular_ref circular_off);
use Data::Dumper;

BEGIN {
    eval q{ use Scalar::Util qw(weaken isweak) };
    if ( $@ ) {
        my $reason
          = "A recent version of Scalar::Util must be installed";
        eval qq{ use Test::More skip_all => "$reason" };
        exit;
    }
    else {
        eval q{ use Test::More tests => 35 };
    }
}

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
    key6 => qr/adsa[sdf]+/,
};
$obj5->{key5}->{key53}->[2] = $obj5->{key5};
$obj5->{key5}->{key54}      = $obj5->{key5}->{key53}->[2];
$obj5->{key6}               = $obj5->{key5}->{key53}->[2];
$obj5->{key5}->{key55}      = $obj5->{key5}->{key53}->[2];

my $obj6  = { key1 => undef };
my $obj6b = $obj6;
my $V2    = [ 1, undef, \5, sub { } ];
for ( 1 .. 50 ) {
    $obj6b->{key2} = bless {} => 'Test';
    $obj6b->{key1} = $V2;
    $obj6b         = $obj6b->{key2};
    $obj6b->{key3} = [$obj6];              # \$obj6 fails
}

ok( !has_circular_ref( $thing ), "Not a circular ref" );
{
    is( circular_off( $thing ), 0, "No circular ref broken" );
}

my $ref = has_circular_ref( $obj );
ok( $ref, "Got a circular reference" );
is( circular_off( $obj ), 1, "Weaken circular references" );
is( circular_off( $obj ), 0, "No more weaken circular references" );
ok( !has_circular_ref( $obj ), "No more circular ref" );

ok( !has_circular_ref( $obj2 ), "No circular reference" );
is( circular_off( $obj2 ), 0, "No circular ref broken" );

ok( has_circular_ref( [ $obj3, $obj4, $obj5 ] ),
    "Got a circular reference" );
is( circular_off( [ $obj3, $obj4, $obj5 ] ),
    4, "Weaken circular references" );
ok( !has_circular_ref( [ $obj3, $obj4, $obj5 ] ),
    "No more circular ref" );

ok( has_circular_ref( $obj6 ),          "Got a circular reference" );
ok( $obj6 == has_circular_ref( $obj6 ), "Match reference" );
is( circular_off( $obj6 ), 50, "Weaken 50 circular refs" );
ok( !has_circular_ref( $obj6 ), "Got a circular reference" );

ok( !has_circular_ref(), "No circular reference" );
ok( !has_circular_ref( [] ), "No circular reference" );
ok( !has_circular_ref( [ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\$ref ] ),
    "Has circular reference" );

my $spy;
{
    my $obj7 = { key1 => {} };
    $obj7->{key1}->{key11} = $obj7->{key1};
    $spy = $obj7->{key1};
    weaken( $spy );
    ok( isweak( $spy ),            "got a spy" );
    ok( has_circular_ref( $obj7 ), "Got a circular reference" );
    is( circular_off( $obj7 ), 1, "Removed circular refs" );
}
ok( !$spy, "No memory leak" );

my $obj8
  = bless { key1 => bless { parent => undef, } => 'Bar', } => 'Foo';
$obj8->{key1}->{parent} = $obj8;
ok( has_circular_ref( $obj8 ), "Got circular" );
is( circular_off( $obj8 ), 1, "removed circular" );
ok( isweak( $obj8->{key1}->{parent} ), "is weak" );
ok( !has_circular_ref( $obj8 ),        "no circular" );
ok( !circular_off( $obj8 ),            "removed circular" );

my $obj9
  = bless { key1 => bless { parent => undef, } => 'Bar', } => 'Foo';
$obj9->{key1}->{parent} = $obj9;
ok( has_circular_ref( $obj9 ), "got circular" );
my $obj91 = $obj9->{key1};
weaken( $obj9->{key1} );
ok( isweak( $obj9->{key1} ),    "is weak" );
ok( !has_circular_ref( $obj9 ), "no circular" );
ok( !circular_off( $obj9 ),     "no circular" );

$obj8 = {};
$obj8->{a} = \$obj8;
is( circular_off( $obj8 ), 1, "Removed circular refs" );

$obj8 = [];
$obj8->[0] = \$obj8;
is( circular_off( $obj8 ), 1, "Removed circular refs" );

$obj8 = [];
$obj8->[1] = \$obj8;
is( circular_off( $obj8 ), 1, "Removed circular refs" );
