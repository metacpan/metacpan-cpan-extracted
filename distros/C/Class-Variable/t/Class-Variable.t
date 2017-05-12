#!/usr/bin/perl -It
package main;
use strict;use warnings;

use Test::More tests => 27;
BEGIN { use_ok('Class::Variable') };

use_ok('Foo');
use_ok('Bar');

my $foo = Foo->new();

my $val = int(rand 10000);

$foo->public1 = ++$val;
is( $foo->public1, $val, "Public base class variable direct setting and getting");

eval{ my $var = $foo->protected1; };
ok( $@ =~ /Access violation: protected variable/, "Protected base class variable reading protection" );

eval{ $foo->protected1 = ++$val; };
ok( $@ =~ /Access violation: protected variable/, "Protected base class variable writing protection" );

eval{ my $var = $foo->private1; };
ok( $@ =~ /Access violation: private variable/, "Private base class variable reading protection" );

eval{ $foo->private1 = ++$val; };
ok( $@ =~ /Access violation: private variable/, "Private base class variable writing protection" );

$foo->set_protected_foo(++$val);
is( $foo->get_protected_foo, $val, 'Protected base class variable access using getter and setter methods');

$foo->set_private_foo(++$val);
is( $foo->get_private_foo, $val, 'Private base class variable access using getter and setter methods');

my $bar = Bar->new();

$bar->public1 = ++$val;
is( $bar->public1, $val, "Base class public variable direct setting and getting via subclass");

$bar->public2 = ++$val;
is( $bar->public2, $val, "Subclass public variable direct setting and getting");

eval{ my $var = $bar->protected1; };
ok( $@ =~ /Access violation: protected variable/, "Base class protected variable reading protection via subclass" );

eval{ $bar->protected1 = ++$val; };
ok( $@ =~ /Access violation: protected variable/, "Base class protected variable writing protection via subclass" );

eval{ my $var = $bar->private1; };
ok( $@ =~ /Access violation: private variable/, "Base class private variable reading protection via subclass" );

eval{ $bar->private1 = ++$val; };
ok( $@ =~ /Access violation: private variable/, "Base class private variable writing protection via subclass" );

eval{ my $var = $bar->protected2; };
ok( $@ =~ /Access violation: protected variable/, "Child class protected variable reading protection" );

eval{ $bar->protected2 = ++$val; };
ok( $@ =~ /Access violation: protected variable/, "Child class protected variable writing protection" );

eval{ my $var = $bar->private2; };
ok( $@ =~ /Access violation: private variable/, "Child class private variable reading protection" );

eval{ $bar->private2 = ++$val; };
ok( $@ =~ /Access violation: private variable/, "Child class private variable writing protection" );


$bar->set_protected_foo(++$val);
is( $bar->get_protected_foo, $val, 'Protected base class variable access using inherited getter and setter methods');

$bar->set_private_foo(++$val);
is( $bar->get_private_foo, $val, 'Private base class variable access using inherited getter and setter methods');

$bar->set_protected_bar(++$val);
is( $bar->get_protected_bar, $val, 'Protected child class variable access using getter and setter methods');

$bar->set_private_bar(++$val);
is( $bar->get_private_bar, $val, 'Private child class variable access using getter and setter methods');

$bar->set_protected_foo_bar(++$val);
is( $bar->get_protected_foo_bar, $val, 'Protected base class variable access using subclass getter and setter methods');

eval{ $bar->get_private_foo_bar(); };
ok( $@ =~ /Access violation: private variable/, "Base class private variable reading protection for subclass methods" );

eval{ $bar->set_private_foo_bar(); };
ok( $@ =~ /Access violation: private variable/, "Base class private variable writing protection for subclass methods" );
