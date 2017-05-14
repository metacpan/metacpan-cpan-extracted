#!/usr/bin/perl

use Test;
BEGIN { plan tests => 28 }

########################################################################

package MyObject;

use Class::MakeMethods::Standard::Inheritable (
  'Standard::Hash:new' => 'new',
  scalar => [ 'a', 'b' ],
);

########################################################################

package MyObject::CornedBeef;
@ISA = 'MyObject';

use Class::MakeMethods::Standard::Inheritable (
  scalar => 'c',
);

########################################################################

package main;

ok( 1 );

# Constructor: new()
ok( ref MyObject->can('new') eq 'CODE' );

# Two similar accessors with undefined values
ok( ref MyObject->can('a') eq 'CODE' );
ok( ! defined MyObject->a() );

ok( ref MyObject->can('b') eq 'CODE' );
ok( ! defined MyObject->b() );

# Pass a value to save it in the named slot
ok( MyObject->a('Foozle') eq 'Foozle' );
ok( MyObject->a() eq 'Foozle' );

# Instance
ok( $obj_1 = MyObject->new() );
ok( ref $obj_1 eq 'MyObject' );
ok( ref $obj_1->can('a') eq 'CODE' );
ok( ref $obj_1->can('b') eq 'CODE' );

# Inheritable, but overridable
ok( $obj_1->a() eq 'Foozle' );
ok( $obj_1->a('Foible') eq 'Foible' );
ok( $obj_1->a() eq 'Foible' );

# Class is not affect by change of instance
ok( MyObject->a() eq 'Foozle' );

# And instances are distinct
ok( $obj_2 = MyObject->new() );
ok( $obj_2->a() eq 'Foozle' );

ok( $obj_1->a() eq 'Foible' );

# Pass undef to clear the slot and re-inherit
ok( ! defined $obj_1->a(undef) );
ok( $obj_1->a() eq 'Foozle' );

# Subclass inherits values 
ok( MyObject::CornedBeef->a() eq 'Foozle' );

# And instances of subclass also inherit
ok( $obj_3 = MyObject::CornedBeef->new() );
ok( $obj_3->a() eq 'Foozle' );

# Change the subclass and you modify it's instances
ok( MyObject::CornedBeef->a('Flipper') eq 'Flipper' );
ok( $obj_3->a() eq 'Flipper' );

# Superclass and its instances are still isolated
ok( MyObject->a() eq 'Foozle' );
ok( $obj_1->a() eq 'Foozle' );

########################################################################

1;
