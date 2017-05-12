#!/usr/bin/perl

use Test;
BEGIN { plan tests => 19 }

########################################################################

package MyObject;

use Class::MakeMethods::Basic::Array (
  new => 'new',
  scalar => [ 'a', 'b' ],
);

########################################################################

package MyObject::CornedBeef;

BEGIN { @ISA = 'MyObject' };

use Class::MakeMethods::Basic::Array (
  scalar => 'c',
);

########################################################################

package main;

ok( 1 );

# Constructor: new()
ok( ref MyObject->can('new') eq 'CODE' );
ok( $obj_1 = MyObject->new() );
ok( ref $obj_1 eq 'MyObject' );

# Two similar accessors with undefined values
ok( ref $obj_1->can('a') eq 'CODE' );
ok( ! defined $obj_1->a() );

ok( ref $obj_1->can('b') eq 'CODE' );
ok( ! defined $obj_1->b() );

# Pass a value to save it in the named slot
ok( $obj_1->a('Foo') eq 'Foo' );
ok( $obj_1->a() eq 'Foo' );

# Pass undef to clear the slot
ok( ! defined $obj_1->a(undef) );
ok( ! defined $obj_1->a() );

# Constructor accepts list of key-value pairs to intialize with
ok( $obj_2 = MyObject->new( a => 'Bar', b => 'Baz' ) );
ok( $obj_2->a() eq 'Bar' and $obj_2->b() eq 'Baz' );

# Copy instances by calling new() on them
ok( $obj_3 = $obj_2->new( b => 'Bowling' ) );
ok( $obj_2->a() eq 'Bar' and $obj_2->b() eq 'Baz' ); # Original is unchanged
ok( $obj_3->a() eq 'Bar' and $obj_3->b() eq 'Bowling' );

# Basic subclasses work as expected, at least in the simplest cases.
ok( $obj_4 = MyObject::CornedBeef->new( a => 'Foo', b => 'Bar', c => 'Baz' ) );
ok( $obj_4->a() eq 'Foo' and $obj_4->b() eq 'Bar' and $obj_4->c() eq 'Baz' );

1;
