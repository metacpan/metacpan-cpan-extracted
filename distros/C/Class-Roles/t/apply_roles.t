#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More tests => 4;

my $module = 'Class::Roles';
use_ok( $module ) or exit;

# define the role
package Greeting;

use Class::Roles role => 'greet';

sub greet { 'greeting' } 

# define the class to which to apply the role
package Cashier;

sub check { 'checking' }

sub bag   { 'bagging' }

package main;

ok( ! Cashier->can( 'greet' ),
	'Role should not bleed into class unless applied' );

Class::Roles->import(
	apply => {
		to   => 'Cashier',
		role => 'Greeting',
	}
);

ok(   Cashier->can( 'greet' ),
	'... but should be there after being applied' );
is( Cashier->greet(), 'greeting',
	'... the correct method' );
