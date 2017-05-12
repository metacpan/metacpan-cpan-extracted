#!/usr/bin/perl

# Copied from 16_pointcut_returning with all the tests reversed.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Test::NoWarnings;
use Test::Exception;
use Aspect;





######################################################################
# Test the regexp exception case

after {
	$_->exception('three');
} call qr/^Foo::/
& returning;

throws_ok(
	sub { Foo::one() },
	qr/^one/,
	'Hooked positive string exception is in the pointcut',
);

throws_ok(
	sub { Foo::two() },
	qr/^two/,
	'Hooked negative string exception is not in the pointcut',
);

throws_ok(
	sub { Foo::three() },
	'Exception1',
	'Hooked negative object exception is not in the pointcut',
);

throws_ok(
	sub { Foo::four() },
	'Exception2',
	'Hooked negative object exception is not in the pointcut',
);

throws_ok(
	sub { Foo::five() },
	qr/^three/,
	'Hooked non-exception was trapped and threw an exception',
);





######################################################################
# Support Classes

package Foo;

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
