#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "Context::Handle" => "context_sensitive";

use Want;

sub SomeClass::foo { "object" };

my @array = (qw/this is an array/);
my %hash = (qw/this is a hash/);

sub complex {
	if ( want("SCALAR") ) {
		if ( want("REF") ) {
			if ( want("ARRAY") ) {
				return \@array;
			} elsif ( want("HASH") ) {
				return \%hash;
			} elsif ( want("OBJECT") ) {
				return bless {}, "SomeClass";
			} elsif ( want("CODE") ) {
				return sub { "code" }
			} else {
				return \"scalar ref";
			}
		} elsif ( want("BOOL") ) {
			return undef;
		} else {
			return "scalar";
		}
	} elsif ( want("LIST") ) {
		return qw/this is a list/;
	} elsif ( want("VOID") )  {
		return;
	} else { die "unknown context" }
}

sub noop_wrap {
	complex();
}

sub is_wrapped {
	my $rv = context_sensitive { complex() };
	use Data::Dumper;
	local $Test::Builder::Level = 2;
	isa_ok( $rv->rv_container, "Context::Handle::RV::$_[0]" ) or warn Dumper($rv);
	$rv->return;
	fail("this should not be reached");
}

{
	my $scalar = complex();
	is( $scalar, "scalar", "scalar yields scalar" );
}

{
	my $scalar = is_wrapped("Scalar");
	is( $scalar, "scalar", "wrapped scalar yields scalar" );
}


foreach my $sub ( \&complex, \&noop_wrap, sub { is_wrapped("Scalar") } ) {
	my $scalar = $sub->();
	is( $scalar, "scalar", "correct value in context");
}

foreach my $sub ( \&complex, \&noop_wrap, sub { is_wrapped("RefScalar") } ) {
	my $scalar = ${ $sub->() };
	is( $scalar, "scalar ref", "correct value in scalar deref context");
}

my $i;
foreach my $sub ( \&complex, \&noop_wrap, sub { is_wrapped("RefArray") } ) {
	my $scalar = $sub->()->[3];
	is( $scalar, "array", "correct value in array deref context");

	$sub->()->[2] = ++$i;
	is( $sub->()->[2], $i, "array ref is mutable");
}

foreach my $sub ( \&complex, \&noop_wrap, sub { is_wrapped("RefHash") } ) {
	my $scalar = $sub->()->{a};
	is( $scalar, "hash", "correct value in hash deref context");

	$sub->()->{this} = ++$i;
	is( $sub->()->{this}, $i, "array ref is mutable");
}


foreach my $sub ( \&complex, \&noop_wrap, sub { is_wrapped("Bool") } ) {
	my $bool;
	if ( $sub->() ) {
		$bool = "true";
	} else {
		$bool = "false";
	}

	is( $bool, "false", "correct value in bool context");
}

foreach my $sub ( \&complex, \&noop_wrap, sub { is_wrapped("RefObject") } ) {
	is( $sub->()->foo, "object", "correct value in object deref context" );
}

foreach my $sub ( \&complex, \&noop_wrap, sub { is_wrapped("RefCode") } ) {
	is( $sub->()->(), "code", "correct value in code deref context" );
}


is_wrapped("Void");


{
	my $hash_val = ${ is_wrapped("RefScalar") };
	is( $hash_val, "scalar ref", "wrapped rv ok" );
}

{
	my $hash_val = complex()->{a};
	is( $hash_val, "hash", "hash value extracted" );
}
{
	my $hash_val = is_wrapped("RefHash")->{a};
	is( $hash_val, "hash", "wrapped rv ok" );
}
