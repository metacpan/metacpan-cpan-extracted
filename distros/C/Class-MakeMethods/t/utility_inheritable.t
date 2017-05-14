#!/usr/bin/perl

use Test;
BEGIN { plan tests => 11 }

########################################################################

package MyClass;
sub new { my $class = shift; bless { @_ }, $class }

package MySubclass;
@ISA = 'MyClass';

########################################################################

package main;

use Class::MakeMethods::Utility::Inheritable qw( get_vvalue set_vvalue );

ok(1);

########################################################################

my $obj = MyClass->new();
my $sobj = MySubclass->new();

my $dataset = {};

ok( ! defined get_vvalue($dataset, 'MyClass') );
set_vvalue($dataset, 'MyClass', 'Foobar');
ok( get_vvalue($dataset, 'MyClass') eq 'Foobar' );

ok( get_vvalue($dataset, $obj) eq 'Foobar' );
set_vvalue($dataset, $obj, 'Foible');
ok( get_vvalue($dataset, $obj) eq 'Foible' );

ok( get_vvalue($dataset, 'MySubclass') eq 'Foobar' );
ok( get_vvalue($dataset, $sobj) eq 'Foobar' );
set_vvalue($dataset, 'MySubclass', 'Foozle'); 
ok( get_vvalue($dataset, 'MySubclass') eq 'Foozle' );
ok( get_vvalue($dataset, 'MyClass') eq 'Foobar' );

ok( get_vvalue($dataset, $sobj) eq 'Foozle' );
set_vvalue($dataset, $sobj, 'Frosty');
ok( get_vvalue($dataset, $sobj) eq 'Frosty' );

########################################################################

1;
