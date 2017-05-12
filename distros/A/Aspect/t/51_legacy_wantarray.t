#!/usr/bin/perl

# Testing of the three wantarray-related pointcuts.
# Because each advice type generates different code,
# it's important to test with each different variation.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 16;
use Test::NoWarnings;
use Test::Exception;
use Aspect ':deprecated';

use vars qw{$COUNT};





######################################################################
# Wantarray with after_returning() advice

$COUNT = 0;

Aspect::after_returning { $COUNT += 1   } call 'Foo::after_returning_one'   & wantlist;
Aspect::after_returning { $COUNT += 10  } call 'Foo::after_returning_two'   & wantscalar;
Aspect::after_returning { $COUNT += 100 } call 'Foo::after_returning_three' & wantvoid;

SCOPE: {
	my @l = Foo::after_returning_one();
	my $s = Foo::after_returning_one();
	Foo::after_returning_one();
}
is( $COUNT, 1, 'Matched wantlist' );

SCOPE: {
	my @l = Foo::after_returning_two();
	my $s = Foo::after_returning_two();
	Foo::after_returning_two();
}
is( $COUNT, 11, 'Matched wantscalar' );

SCOPE: {
	my @l = Foo::after_returning_three();
	my $s = Foo::after_returning_three();
	Foo::after_returning_three();
}
is( $COUNT, 111, 'Matched wantvoid' );





######################################################################
# Wantarray with after_throwing() advice

$COUNT = 0;

Aspect::after_throwing { $COUNT += 1   } call 'Foo::after_throwing_one'   & wantlist;
Aspect::after_throwing { $COUNT += 10  } call 'Foo::after_throwing_two'   & wantscalar;
Aspect::after_throwing { $COUNT += 100 } call 'Foo::after_throwing_three' & wantvoid;

SCOPE: {
	throws_ok(
		sub { my @l = Foo::after_throwing_one(); },
		qr/one/,
		'after_throwing wantarray array'
	);
	throws_ok(
		sub { my $s = Foo::after_throwing_one(); },
		qr/one/,
		'after_throwing wantarray scalar'
	);
	throws_ok(
		sub { Foo::after_throwing_one(); },
		qr/one/,
		'after_throwing wantarray void'
	);
}
is( $COUNT, 1, 'Matched wantlist' );

SCOPE: {
	throws_ok(
		sub { my @l = Foo::after_throwing_two(); },
		qr/two/,
		'after_throwing wantscalar array'
	);
	throws_ok(
		sub { my $s = Foo::after_throwing_two(); },
		qr/two/,
		'after_throwing wantscalar scalar'
	);
	throws_ok(
		sub { Foo::after_throwing_two(); },
		qr/two/,
		'after_throwing wantscalar void'
	);
}
is( $COUNT, 11, 'Matched wantscalar' );

SCOPE: {
	throws_ok(
		sub { my @l = Foo::after_throwing_three(); },
		qr/three/,
		'after_throwing wantvoid array'
	);
	throws_ok(
		sub { my $s = Foo::after_throwing_three(); },
		qr/three/,
		'after_throwing wantvoid scalar'
	);
	throws_ok(
		sub { Foo::after_throwing_three(); },
		qr/three/,
		'after_throwing wantvoid void'
	);
}
is( $COUNT, 111, 'Matched wantvoid' );





######################################################################
# Support Methods

package Foo;

sub after_returning_one   { 1 }

sub after_returning_two   { 2 }

sub after_returning_three { 3 }

sub after_throwing_one    { die 'one'   }

sub after_throwing_two    { die 'two'   }

sub after_throwing_three  { die 'three' }
