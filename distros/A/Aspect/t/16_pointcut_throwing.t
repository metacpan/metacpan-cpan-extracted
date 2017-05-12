#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 24;
use Test::NoWarnings;
use Test::Exception;
use Aspect;





######################################################################
# Test the regexp exception case

SCOPE: {
	my $advice = after {
		$_->exception('three');
	} call qr/^A::/
	& throwing qr/two/;

	is( $advice->installed, 5, 'Installed to 5 functions' );

	throws_ok(
		sub { A::one() },
		qr/^one/,
		'Hooked positive string exception is in the pointcut',
	);

	throws_ok(
		sub { A::two() },
		qr/^three/,
		'Hooked negative string exception is not in the pointcut',
	);

	throws_ok(
		sub { A::three() },
		'Exception1',
		'Hooked negative object exception is not in the pointcut',
	);

	throws_ok(
		sub { A::four() },
		'Exception2',
		'Hooked negative object exception is not in the pointcut',
	);

	is( A::five(), 'five', 'A::five() returns without throwing' );
}





######################################################################
# Test the object exception case

SCOPE: {
	my $advice = after {
		$_->exception('three');
	} call qr/^BB::/
	& throwing 'Exception1';
	is( $advice->installed, 5, 'Installed to 5 functions' );

	throws_ok(
		sub { BB::one() },
		qr/^one/,
		'Hooked negative string exception is not in the pointcut',
	);

	throws_ok(
		sub { BB::two() },
		qr/^two/,
		'Hooked negative string exception is not in the pointcut',
	);

	throws_ok(
		sub { BB::three() },
		qr/^three/,
		'Hooked positive object exception is in the pointcut',
	);

	throws_ok(
		sub { BB::four() },
		'Exception2',
		'Hooked negative object exception is not in the pointcut',
	);

	is( BB::five(), 'five', 'BB::five() returns without throwing' );
}





######################################################################
# Test the null throwing case

SCOPE: {
	my $advice = after {
		$_->exception('three');
	} call qr/^C::/
	& throwing;
	is( $advice->installed, 5, 'Installed to 5 functions' );

	throws_ok(
		sub { C::one() },
		qr/^three/,
		'Hooked negative string exception is in the pointcut',
	);

	throws_ok(
		sub { C::two() },
		qr/^three/,
		'Hooked negative string exception is in the pointcut',
	);

	throws_ok(
		sub { C::three() },
		qr/^three/,
		'Hooked positive object exception is in the pointcut',
	);

	throws_ok(
		sub { C::four() },
		qr/^three/,
		'Hooked negative object exception is in the pointcut',
	);

	is( C::five(), 'five', 'C::five() returns without throwing' );
}





######################################################################
# Test construct for "every exception except foo"

SCOPE: {
	my $advice = after {
		$_->exception('three');
	} call qr/^D::/
	& throwing()
	& ! throwing 'Exception1';

	throws_ok(
		sub { D::one() },
		qr/^three/,
		'Hooked negative string exception is in the pointcut',
	);

	throws_ok(
		sub { D::two() },
		qr/^three/,
		'Hooked negative string exception is in the pointcut',
	);

	throws_ok(
		sub { D::three() },
		'Exception1',
		'Hooked positive object exception is in the pointcut',
	);

	throws_ok(
		sub { D::four() },
		qr/^three/,
		'Hooked negative object exception is in the pointcut',
	);

	is( D::five(), 'five', 'D::five() returns without throwing' );
}





######################################################################
# Support Classes

package A;

sub one {
	die 'one';
}

sub two {
	die 'two';
}

sub three {
	Exception1->throw('one');
}

sub four {
	Exception2->throw('two');
}

sub five {
	return 'five';
}

package BB;

sub one {
	die 'one';
}

sub two {
	die 'two';
}

sub three {
	Exception1->throw('one');
}

sub four {
	Exception2->throw('two');
}

sub five {
	return 'five';
}

package C;

sub one {
	die 'one';
}

sub two {
	die 'two';
}

sub three {
	Exception1->throw('one');
}

sub four {
	Exception2->throw('two');
}

sub five {
	return 'five';
}

package D;

sub one {
	die 'one';
}

sub two {
	die 'two';
}

sub three {
	Exception1->throw('one');
}

sub four {
	Exception2->throw('two');
}

sub five {
	return 'five';
}

package Exception1;

sub throw {
	my $class = shift;
	my $self  = bless [ @_ ], $class;
	die $self;
}

package Exception2;

sub throw {
	my $class = shift;
	my $self  = bless [ @_ ], $class;
	die $self;
}

1;
