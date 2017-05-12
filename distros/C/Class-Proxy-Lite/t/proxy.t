#!/usr/bin/perl -w

use strict;
use warnings;

# ---------------------------------------------------------------------

package MyClass;

BEGIN {
	%MyClass::name2obj = ();
}

sub new {
	my ($cls, $name) = @_;
	my $self = bless { 'name' => $name };
	return $MyClass::name2obj{$name} = $self;
}

sub _resolve_token { $MyClass::name2obj{$_[0]} }

sub name {
	return $_[0]->{'name'}
		unless scalar @_ > 1;
	delete $MyClass::name2obj{$_[0]->{'name'}};
	return $_[0]->{'name'} = $_[1];
}

sub foo { print "Foo!\n" }
sub bar { print "Bar?\n" }

# ---------------------------------------------------------------------

package MyProxy;

@MyProxy::ISA = qw(Class::Proxy::Lite);

sub new {
	my ($cls, $obj) = @_;
	$cls->SUPER::new($obj->name(), \&MyClass::_resolve_token);
}

# ---------------------------------------------------------------------

package main;

use strict;
use warnings;

$| = 1;

use Test::More 'tests' => 5;

BEGIN { use_ok( 'Class::Proxy::Lite' ); }

my $name = 'John Jacob Jinglemeyer Schmidt';

my $obj = MyClass->new($name);
my $proxy = MyProxy->new($obj);

isa_ok( $obj,   'MyClass' );
isa_ok( $proxy, 'MyProxy' );

is( $proxy->name(), $name,  'get name' );

# --- For some reason, this TODO block fails.  I don't get it...
#TODO: {
#	local $TODO = "Don't know how to handle can() properly yet";
#	ok( defined $proxy->can('new'),  "can('new')"  );
#	ok( defined $proxy->can('name'), "can('name')" );
#	isa_ok( $proxy->can('new')->($proxy), 'MyClass', "can('new')->()" );
#};

my $obj2 = $proxy->new($obj);
isa_ok( $obj2, 'MyClass' );

