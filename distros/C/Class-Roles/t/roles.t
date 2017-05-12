#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More tests => 17;

my $module = 'Class::Roles';
use_ok( $module ) or exit;

package bark;

use Class::Roles role => 'bark';

sub bark
{
	return 'woof woof';
}

package animal;

use Class::Roles role => [qw( eat sleep )];

sub eat
{
	return 'chomp chomp';
}

sub sleep
{
	return 'snore snore';
}

package itches;

use Class::Roles role => 'scratch';

sub scratch
{
	return 'itchy scratch';
}

package Dog;

sub scratch
{
	return 'doggy itch';
}

Class::Roles->import( does => 'bark' );

::diag( '"does" should import named method' );
::can_ok( __PACKAGE__, 'bark' );
::is( \&bark, \&bark::bark, '... from role class' );

Class::Roles->import( does => 'animal' );

::diag( '"does" should import collection of named methods from role' );
::can_ok( __PACKAGE__, 'eat' );
::is( \&eat, \&animal::eat,     '... from role class' );

::can_ok( __PACKAGE__, 'sleep' );
::is( \&sleep, \&animal::sleep, '... from role class' );

Class::Roles->import( does => 'itches' );

::diag( '"does" should mark class as fulfilling role' );
::can_ok( __PACKAGE__, 'scratch' );
::isnt( \&scratch, \&itches::scratch, '... not overriding existing method' );
::is( scratch(), 'doggy itch',        '... not one bit' );

package main;

diag( 'does() should work on all classes' );
can_ok( 'Dog', 'does' );
for my $role (qw( animal bark itches ))
{
	ok( Dog->does( $role ),   "... true for roles the class can do ($role)" );
}
ok( ! Dog->does( 'fly' ),     '... false for roles the class cannot do' );
ok( animal->does( 'animal' ), '... roles should do themselves' );

package RoboDog;

@RoboDog::ISA = 'Dog';

package main;

diag( 'does() should work on sub classes' );
ok( RoboDog->does( 'animal' ), 'roles should also apply to sub classes' );
