#!/usr/bin/perl
#
#		Test script for Attribute::Method::Typeable
#		$Id: 02_CallControl.t,v 1.5 2004/10/20 21:37:30 phaedrus Exp $
#
#		Before `make install' is performed this script should be runnable with
#		`make test'. After `make install' it should work as `perl test.pl'
#
#		Please do not commit any changes you make to the module without a
#		successful 'make test'!
#

# test classes:

package ClassA;

BEGIN {
	my $mixinLoaded = eval { require mixin; return 1; };
	if($mixinLoaded) { mixin->import('Attribute::Method::Typeable'); }
	else { require base; base->import('Attribute::Method::Typeable'); }
}

use strict;

my $classVal = 0;

sub new : Constructor() {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
				number => 1,
			   };
	bless($self, $class);
}

sub methodA :Public() {
	my $self = shift;
	return $self->{number} + 1;
}

sub methodB : Protected() {
	my $self = shift;
	return $self->{number} + 2;
}

sub methodC :Private {
  	my $self = shift;
  	return $self->{number} + 3;
}

sub methodD : Public {
	my $self = shift;
	return $self->methodC;
}

sub classMethodA : Class {
	my $class = shift;
	return ++$classVal;
}

sub methodE : Public {
	my $self = shift;
	return $self->classMethodA;
}

sub abstractMethodA : Abstract( integer, float) {
}

sub abstractMethodB : Virtual() {
}

1;

package ClassB;


BEGIN {
	my $mixinLoaded = eval { require mixin; return 1; };
	if($mixinLoaded) { mixin->import('Attribute::Method::Typeable'); }
	else { require base; base->import('Attribute::Method::Typeable'); }
}

use base qw{ClassA};

sub new :Constructor{ 
	my $proto = shift; 
	my $class = ref($proto) || $proto; 
	my $self = $class->SUPER::new();
	bless($self, $class); 
}

sub methodA : Public {
	my $self = shift;
	return $self->SUPER::methodA;
}

sub methodB : Public {
	my $self = shift;
	return $self->SUPER::methodB;
}

sub methodC : Public {
	my $self = shift;
	return $self->SUPER::methodC;
}


1;

package ClassC;


BEGIN {
	my $mixinLoaded = eval { require mixin; return 1; };
	if($mixinLoaded) { mixin->import('Attribute::Method::Typeable'); }
	else { require base; base->import('Attribute::Method::Typeable'); }
}

use base qw{ClassA};

sub new :Constructor(ClassA){ 
	my $proto = shift; 
	my $class = ref($proto) || $proto; 
	my $thingy = shift;
	my $self = {thingy => $thingy};
	bless($self, $class); 
}

1;

package main;

# always use these:
use strict;
use warnings qw{all};
use Test::SimpleUnit qw{:functions}; #}


Test::SimpleUnit::AutoskipFailedSetup(1);

{
	eval { require Attribute::Method::Typeable; };
}

my $evalError = $@;
my $result = '';
my ($objectA, $objectB);

my @testSuite = (

				 # Setup function
				 {
				  name => 'setup',
				  func => sub {
					  $objectA = ClassA->new;
					  $objectB = ClassB->new;
				  },
				 },

				 # Teardown function
				 {
				  name => 'teardown',
				  func => sub {},
				 },


				 {
				  name => 'Abstract/Virtual Attribute',
				  test => sub {
					  # test ClassA::abstractMethodA
					  assertException( sub {
										   ClassA::abstractMethodA();
									   }, "Didn't throw Exception::MethodError");
					  assertException( sub {
										   $objectA->abstractMethodA();
									   }, "Didn't throw Exception::MethodError");
					  # test ClassA::abstractMethodB
					  assertException( sub {
										   ClassA::abstractMethodB();
									   }, "Didn't throw Exception::MethodError");
					  assertException( sub {
										   $objectA->abstractMethodB();
									   }, "Didn't throw Exception::MethodError");
				  },
				 },

				 {
				  name => 'Constructor Attribute',
				  test => sub {
					  # test ClassA::new
					  assertException( sub {
										   ClassA::new();
									   }, "Didn't throw Exception::MethodError");
					  assertException( sub {
										   ClassA::new(233);
									   }, "Didn't throw Exception::MethodError");
					  assertException( sub {
										   ClassA->new(2233);
									   }, "Didn't throw Exception::MethodError");
					  assertException( sub {
										   ClassA::new('Class');
									   }, "Didn't throw Exception::MethodError");
					  assertException( sub {
										   ClassA::new('ClassQ');
									   }, "Didn't throw Exception::MethodError");
					  assertNoException( sub {
											 $result = ClassA->new();
										 });
					  assertNoException( sub {
											 ClassA->new();
										 });
					  assertInstanceOf( 'ClassA', $result );
					  my $otherObj;
					  assertNoException( sub {
											 $otherObj = $result->new();
										 });
					  assertInstanceOf( 'ClassA', $otherObj );
					  assertNoException( sub {
											 $result = ClassA::new('ClassB');
										 });
					  assertInstanceOf( 'ClassB', $result );
					  my $object = '';
					  assertNoException( sub {
											 $object = ClassB->new;
										 });
					  assertInstanceOf( 'ClassB', $object );

					  # test weird-ass bug:
					  my $classAObj = ClassA->new;
					  assertNoException( sub {
						  ClassC->new($classAObj);
					  });
					  assertNoException( sub {
						  $result = ClassC->new($classAObj);
					  });
					  assert( $result->{thingy} );
					  assertNoException( sub {
						  $result = ClassC->new($classAObj);
					  });
					  assert( $result->{thingy} );
				  },
				 },

				 {
				  name => 'Public Attribute',
				  test => sub {
					  assertException( sub {
										   ClassA::methodA();
									   }, 
									   "Didn't throw Exception::MethodError");
					  assertException( sub {
										   ClassA::methodA('foo');
									   }, 
									   "Didn't throw Exception::MethodError");
					  assertException( sub {
										   ClassA->methodA();
									   }, 
									   "Didn't throw Exception::MethodError");
					  assertException( sub {
										   ClassA::methodA();
									   }, 
									   "Didn't throw Exception::MethodError");
					  assertException( sub {
										   $objectA->methodA('foo');
									   }, 
									   "Didn't throw Exception::MethodError");
					  assertNoException( sub {
											 $result = $objectA->methodA();
										 });
					  assert($result == 2);
  					  assertNoException( sub {
  											 $result = $objectB->methodA();
  										 });
  					  assert($result == 2);
				  },
				 },

				 {
				  name => 'Protected Attribute',
				  test => sub {
					  # can't call it directly
					  assertException( sub {
										   $objectA->methodB;
									   }, 
									   "Didn't throw Exception::MethodError");
					  # can call it indirectly through an object that is it's descendant.
					  assertNoException( sub {
										   $result = $objectB->methodB;
									   });
					  assert( $result == 3 );
				  },
				 },

				 {
				  name => 'Private Attribute',
				  test => sub {
					  # can't call it directly
					  assertException( sub {
										   $objectA->methodC;
									   }, 
									   "Didn't throw Exception::MethodError");
					  # can't call it indirectly through it's descendant.
					  assertException( sub {
										   $objectB->methodC;
									   }, 
									   "Didn't throw Exception::MethodError");
					  # can only call it from a public method or function of that class itself.
					  assertNoException( sub {
											 $result = $objectA->methodD;
										 });
					  assert( $result == 4 );
				  },
				 },

				 {
				  name => 'Class Attribute',
				  test => sub {
					  assertException( sub {
										   ClassA::classMethodA();
									   }, 
									   "Didn't throw Exception::MethodError");
					  assertException( sub {
										   ClassA::classMethodA(bless {});
									   }, 
									   "Didn't throw Exception::MethodError");
					  assertException( sub {
										   ClassA::classMethodA('ClassQ');
									   }, 
									   "Didn't throw Exception::MethodError");
					  assertNoException( sub {
											 $result = ClassA->classMethodA();
										 });
					  assert( $result == 1);
					  assertNoException( sub {
											 $result = $objectA->classMethodA();
										 });
					  assert( $result == 2);
					  assertNoException( sub {
											 $result = ClassB->classMethodA();
										 });
					  assert( $result == 3);
					  assertNoException( sub {
											 $result = $objectB->classMethodA();
										 });
					  assert( $result == 4);
					  assertNoException( sub {
											 $result = ClassA::classMethodA('ClassA');
										 });
					  assert( $result == 5);
					  assertNoException( sub {
											 $result = $objectA->methodE();
										 });
					  assert( $result == 6);
				  },
				 },
				);

runTests(@testSuite);
