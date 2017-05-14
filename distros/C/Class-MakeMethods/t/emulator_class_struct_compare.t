#!/usr/bin/perl

use Test;
BEGIN { plan tests => 44 }

use Class::Struct;
Class::Struct->printem;

package MyStructArray;

use Class::Struct;
struct( 's' => '$', a => '@', h => '%', c => 'My_Other_Class' );

package MyEmuArray;

use Class::MakeMethods::Emulator::Struct;
struct( 's' => '$', a => '@', h => '%', c => 'My_Other_Class' );

package MyStructHash;

use Class::Struct;
struct( MyStructHash => { 's' => '$', a => '@', h => '%', c => 'My_Other_Class' } );

package MyEmuHash;

use Class::MakeMethods::Emulator::Struct;
struct( MyEmuHash => { 's' => '$', a => '@', h => '%', c => 'My_Other_Class' } );

package My_Other_Class;
$i = 1;
sub new { my $self = $i ++; bless \$self } 
sub method { "success $_[1]" }

package main;

foreach my $package ( qw( MyStructArray MyEmuArray MyStructHash MyEmuHash ) ) {
  
  my $obj = $package->new();               # constructor

				    # scalar type accessor:
  ok( $obj->s('new value')   );      # assign to element
  ok( $obj->s eq 'new value' );      # element value
  
				    # array type accessor:
  ok( $obj->a(2, 'list item') );     # assign to array element
  ok( ref $obj->a eq 'ARRAY'  );     # reference to whole array
  ok( $obj->a(2) eq 'list item' );   # array element value
  
				    # hash type accessor:
  ok( $obj->h('x', 'x-value') );    # assign to hash element
  ok( ref $obj->h eq 'HASH'  );      # reference to whole hash
  ok( $obj->h('x') eq 'x-value' );   # hash element value
  
				    # class type accessor:
  ok( $obj->c(My_Other_Class->new()) ); # assign a new object
  ok( ref ($obj->c) eq 'My_Other_Class' ); # object reference
  ok( $obj->c->method(21) eq 'success 21' ); # call method of object
}
