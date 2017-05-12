#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# This is the example from the POD
# modified slightly to work w/o module deps.

use Test::More tests => 4;

use Class::Autouse sub {
	my ($class) = @_;
	if ($class =~ /(^.*)::Wrapper/) {
		my $wrapped_class = $1;
		eval "package $class; ## use Class::AutoloaCAN";
		die $@ if $@;
		no strict 'refs';
		*{$class . '::new' } = sub {
			my $class = shift;
			my $proxy = $wrapped_class->new(@_);
			my $self = bless({proxy => $proxy},$class);
			return $self;
		};

		# If you're on a recent enough version of Perl, you should use Class::AutolaodCAN below
		# and just return the delegator. 
		## *{$class . '::CAN' } = sub {
		*{$class . '::AUTOLOAD' } = sub {
			##my ($obj,$method) = @_;
			my $obj = shift;
			use vars '$AUTOLOAD';
			my ($method) = ($AUTOLOAD =~ /^.*::(\w+)$/);
			
			my $delegate = $wrapped_class->can($method);
			return unless $delegate;
			my $delegator = sub {
				my $self = shift;
				if (ref($self)) {
					return $self->{proxy}->$method(@_);
				}
				else {
					return $wrapped_class->$method(@_);
				}
			};
			*{ $class . '::' . $method } = $delegator;
			
			##return $delegator;	
			$delegator->($obj,@_);
		};
		
		return 1;
	}
	return;
};

package Foo;

sub new { my $class = shift; bless({@_},$class); }

sub class_method { 123 }

sub instance_method { 
	my ($self,$v) = @_; 
	return $v * $self->some_property
}

sub some_property { shift->{some_property} }


package main;

my $x = Foo::Wrapper->new(some_property => 111);
#print $x->some_property,"\n";
#print $x->instance_method(5),"\n";
#print Foo::Wrapper->class_method,"\n";

isa_ok($x,"Foo::Wrapper");
is($x->some_property,111);
is($x->instance_method(5),555);
is($x->class_method,123);
