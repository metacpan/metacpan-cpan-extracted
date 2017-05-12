#!/usr/bin/perl -w

# Main testing for Data::Package

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 15;
use Data::Package;

# Test the normal case
ok( UNIVERSAL::isa('Foo::Data', 'Data::Package'), 'Foo::Data is a Data::Package' );
is_deeply( [ Foo::Data->provides() ],      [ 'Foo' ], '->provides returns as expected' );
is_deeply( [ Foo::Data->provides('Foo') ], [ 'Foo' ], '->provides(Foo) returns as expected' );
is_deeply( [ Foo::Data->provides('Bar') ], [       ], '->provides(Bar) returns as expected' );
my $obj = Foo::Data->get;
isa_ok( $obj, 'Foo' );
$obj = Foo::Data->get('Foo');
isa_ok( $obj, 'Foo' );
$obj = Foo::Data->get('Bar');
is( $obj, undef, '->get(bad) returns undef' );

# Test the inherited case
ok( UNIVERSAL::isa('Bar::Data', 'Data::Package'), 'Bar::Data is a Data::Package' );
is_deeply( [ Bar::Data->provides ],        [ 'Bar' ], '->provides returns as expected' );
is_deeply( [ Bar::Data->provides('Bar') ], [ 'Bar' ], '->provides(Bar) returns as expected' );
is_deeply( [ Bar::Data->provides('Foo') ], [ 'Bar' ], '->provides(Foo) returns as expected' );
$obj = Bar::Data->get;
isa_ok( $obj, 'Bar' );
$obj = Bar::Data->get('Bar');
isa_ok( $obj, 'Bar' );
$obj = Bar::Data->get('Foo');
isa_ok( $obj, 'Foo' );
is_deeply( Bar::Data->get('Bar'), Bar::Data->get('Foo'), '->get(Foo) and ->get(Bar) return the same' );






#####################################################################
# Testing Packages

package Foo;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

package Foo::Data;

use base 'Data::Package';

sub __as_Foo {
	return bless {}, 'Foo';
}

package Bar::Data;

use base 'Data::Package';

sub __as_Bar {
	return bless { a => 1 }, 'Bar';
}

package Bar;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.1';
	@ISA     = 'Foo';
}

1;
