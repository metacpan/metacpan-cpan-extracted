#!/usr/bin/perl

use Test;
BEGIN { plan tests => 6 }

########################################################################

package MyObject;

use Class::MakeMethods::Composite::Inheritable (
  'Composite::Hash:new' => 'new',
  hook => [ 'foo' ],
);

########################################################################

package main;

ok( 1 );

ok( ! defined MyObject->foo() );

MyObject->foo( Class::MakeMethods::Composite::Inheritable->Hook( sub { 
    my $callee = shift;
    return "foo $callee";
} ) );
ok( MyObject->foo() eq "foo MyObject" );

ok( $obj_1 = MyObject->new() );
ok( $obj_1->foo() eq "foo $obj_1" );

$obj_1->foo( Class::MakeMethods::Composite::Inheritable->Hook( sub { 
    my $callee = shift;
    Class::MakeMethods::Composite->CurrentResults(
      map { tr[a-z][A-Z]; $_ } Class::MakeMethods::Composite->CurrentResults()
    );
    return;
} ) );
ok( $obj_1->foo() eq uc("foo $obj_1") );

1;
