#!/usr/bin/perl

# Test the AUTOLOAD params

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 22;
use Class::Adapter::Builder ();
use constant CAB => 'Class::Adapter::Builder';





####################################################################
# Create the Test Classes

CLASS: {
	package My::Object;

	sub new {
		my $class = shift;
		bless { @_ }, $class;
	}

	sub foo { 2 }

	sub bar { $_[0]->{$_[1]} }

	sub _baz { 4 }

	1;
}



CLASS: {
	package My::None;
	local $SIG{'__WARN__'} = sub { die "Hit warning" };
	Test::More::use_ok(
		'Class::Adapter::Builder',
		NEW      => 'My::Object',
		ISA      => '_OBJECT_',
		AUTOLOAD => 0,
	);
}



CLASS: {
	package My::All;
	local $SIG{'__WARN__'} = sub { die "Hit warning" };
	Test::More::use_ok(
		'Class::Adapter::Builder',
		NEW      => 'My::Object',
		ISA      => '_OBJECT_',
		AUTOLOAD => 1,
	);
}



CLASS: {
	package My::Public;
	local $SIG{'__WARN__'} = sub { die "Hit warning" };
	Test::More::use_ok(
		'Class::Adapter::Builder',
		NEW      => 'My::Object',
		ISA      => '_OBJECT_',
		AUTOLOAD => 'PUBLIC',
	);
}





#####################################################################
# Create the Test Objects

sub dies {
	my $code = shift;
	eval { &$code() };
	ok( $@, $_[0] || 'Code dies as expected' );
}

my $object = My::Object->new( a => 3 );
isa_ok( $object, 'My::Object' );
is( $object->foo,      2,     '->foo returns true'            );
is( $object->bar('a'), 3,     '->bar(good) returns correctly' );
is( $object->bar('b'), undef, '->bar(bad) returns undef'      );
is( $object->_baz,     4,     '->baz returns true'            );

my $none   = My::None->new(   a => 3 );
isa_ok( $none, 'My::Object' );
dies( sub { $none->foo }      );
dies( sub { $none->bad('a') } );
dies( sub { $none->_baz } );

my $all    = My::All->new(    a => 3 );
isa_ok( $all, 'My::Object' );
is( $all->foo,      2,     '->foo returns true'            );
is( $all->bar('a'), 3,     '->bar(good) returns correctly' );
is( $all->bar('b'), undef, '->bar(bad) returns undef'      );
is( $all->_baz,     4,     '->baz returns true'            );

my $public = My::Public->new( a => 3 );
isa_ok( $public, 'My::Object' );
is( $public->foo,      2,     '->foo returns true'            );
is( $public->bar('a'), 3,     '->bar(good) returns correctly' );
is( $public->bar('b'), undef, '->bar(bad) returns undef'      );
dies( sub { $public->_baz } );
