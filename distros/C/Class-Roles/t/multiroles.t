#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More tests => 11;

my $module = 'Class::Roles';
use_ok( $module ) or exit;

package MultiRoles;

sub foo;
sub oof;
sub bar;
sub rab;

Class::Roles->import( multi =>
{
	foo => [qw( foo oof )],
	bar => [qw( bar rab )],
});

package FooOnly;

Class::Roles->import( does => 'foo' );

package BarOnly;

Class::Roles->import( does => 'bar' );

package main;

ok(   FooOnly->does( 'foo' ),        'multi-roles should work' );
ok( ! FooOnly->does( 'bar' ),        '... registering only requested roles' );
ok( ! FooOnly->does( 'MultiRoles' ), '... not defining package' );
ok(   FooOnly->can(  'foo' ),        '... importing required methods' );
ok( ! FooOnly->can(  'bar' ),        '... and not unneeded ones' );

ok(   BarOnly->does( 'bar' ),        'multi-roles should work' );
ok( ! BarOnly->does( 'foo' ),        '... registering only requested roles' );
ok( ! FooOnly->does( 'MultiRoles' ), '... not defining package' );
ok(   BarOnly->can(  'rab' ),        '... importing required methods' );
ok( ! BarOnly->can(  'oof' ),        '... and not unneeded ones' );
