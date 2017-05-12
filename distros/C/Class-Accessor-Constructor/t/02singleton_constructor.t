#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 10;

package Foo;
use parent 'Class::Accessor::Constructor';
__PACKAGE__->mk_constructor->mk_accessors(qw(name));
use constant DEFAULTS => (name => 'Shindou Hikaru',);
sub init { }

package Foo::Bar;
our @ISA = 'Foo';
__PACKAGE__->mk_singleton_constructor;

package main;
my $foo = Foo->new;
is($foo->name, 'Shindou Hikaru', 'First Foo object default name');
$foo->name('John Smith');
is($foo->name, 'John Smith', 'First Foo object name');
my $foo2 = Foo->new;
is($foo2->name, 'Shindou Hikaru', 'Second Foo object default name');
$foo2->name('Martin Mayer');
is($foo2->name, 'Martin Mayer', 'Second Foo object name');
is($foo->name,  'John Smith',   'First Foo object name is unchanged');
my $bar = Foo::Bar->new;
is($bar->name, 'Shindou Hikaru', 'First Foo::Bar object default name');
$bar->name('John Smith');
is($bar->name, 'John Smith', 'First Foo::Bar object name');
my $bar2 = Foo::Bar->new;
is($bar->name, 'John Smith', 'Second Foo::Bar object retains previous name');
$bar2->name('Martin Mayer');
is($bar2->name, 'Martin Mayer', 'Second Foo::Bar object name');
is($bar->name,  'Martin Mayer', 'First Foo::Bar object name has been changed');
