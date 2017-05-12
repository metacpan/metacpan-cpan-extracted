#!/usr/bin/perl
#
#		Test script for Attribute::Method::Typeable
#		$Id: 01_ArgumentControl.t,v 1.5 2004/10/20 21:37:30 phaedrus Exp $
#
#		Before `make install' is performed this script should be runnable with
#		`make test'. After `make install' it should work as `perl test.pl'
#
#		Please do not commit any changes you make to the module without a
#		successful 'make test'!
#

# test classes:

package TestPackage;

BEGIN {
	my $mixinLoaded = eval { require mixin; return 1; };
	if($mixinLoaded) { mixin->import('Attribute::Method::Typeable'); }
	else { require base; base->import('Attribute::Method::Typeable'); }
}

use strict;
# used for testing basic function usage
sub functionA :Function() {
	my $number = 1;
	my $otherNumber = 0;
	return $number + $otherNumber;
}

# used for testing basic function usage
sub functionB :Function {
	my $number = 2;
	my $otherNumber = -1;
	return $number + $otherNumber;
}

# used to test scalar attribute
sub scalarA :Function( scalar ) {
	my $scalar = shift;
	return "$scalar";
}
# used to test literal attribute
sub literalA :Function( literal ) {
	my $literal = shift;
	return "$literal";
}
# used to test whole attribute
sub wholeA :Function( whole ) {
	my $wholeNum = shift;
	$wholeNum += 1;
	return $wholeNum;
}

# used to test integer attribute
sub integerA :Function( integer ) {
	my $integerNum = shift;
	$integerNum += 1;
	return $integerNum;
}

# used to test real attribute
sub realA :Function( real ) {
	my $realNum = shift;
	$realNum += 1;
	return $realNum;
}

# used to test decimal attribute
sub decimalA :Function( decimal ) {
	my $decimalNum = shift;
	$decimalNum += 1.0;
	return $decimalNum;
}

# used to test float attribute
sub floatA :Function( float ) {
	my $floatNum = shift;
	$floatNum += 1.0;
	return $floatNum;
}

# used to test char(acter) attribute(s)
sub characterA :Function( character ) {
	my $char = shift;
	return 2 if($char eq 'q');
	return 1;
}

sub charA :Function( char ) {
	my $char = shift;
	return 2 if($char eq 'q');
	return 1;
}

# used to test string attribute
sub stringA :Function( string ) {
	my $string = shift;
	return 'Hello ' . $string;
}

# used to test vector attribute
sub vectorA : Function( vector ) {
	my @numbers = @_;
	my $tot = 0;
	foreach my $number (@numbers) {
		$tot += $number;
	}
	return $tot;
}

# used to test Scalar attribute
sub functionC :Function( Scalar ) {
	my $number = shift;
	my $otherNumber = -1;
	return $number + $otherNumber;
}

# used to test Scalar attribute
sub functionD :Function( Scalar ) {
	my $message = shift;
	my $otherMessage = " world.";
	return $message . $otherMessage;
}

# used to test Scalar attribute
sub functionE :Function( Scalar ) {
	my $numberRef = shift;
	return --$$numberRef;
}

# used to test Scalar attribute and multiple arguments
sub functionF :Function(Scalar, Scalar) {
	return $_[0] + $_[1];
}

# used to test Scalar attribute and multiple arguments
sub functionG : Function(Scalar Scalar) {
	return $_[0] + $_[1];
}

# used to test Scalar attribute and multiple arguments
sub functionH : Function(Scalar Scalar Scalar) {
	return $_[0] + $_[1] + $_[2];
}

# used to test ARRAY attribute
sub functionI : Function(ARRAY) {
	my $arrayRef = shift;
	my $dracula = 0;
	foreach my $val (@{$arrayRef}) {
		$val++;
		$dracula++;
	}
	return $dracula;
}

sub functionJ : Function(ARRAY ARRAY) {
	my $arrayRef = shift;
	my $otherArrayRef = shift;
	push(@{$arrayRef}, @{$otherArrayRef});
	unshift( @{$otherArrayRef}, @{$arrayRef});
	return @{$arrayRef};
}

sub functionK : Function(HASH) {
	my $hashRef = shift;
	my %otherHash = ();
	foreach my $key (keys %{$hashRef}) {
		$otherHash{ $hashRef->{$key} } = $key;
		$hashRef->{ $hashRef->{$key} } = $key;
	}
	return \%otherHash;
}

sub functionL : Function(HASH HASH) {
	my $firstHashRef = shift;
	my $secondHashRef = shift;
	my %firstTmpHash = (%{$firstHashRef});
	my %secondTmpHash = (%{$secondHashRef});
	my $dracula = 0;
	foreach my $key (keys %firstTmpHash){
		$secondHashRef->{$key} = $firstTmpHash{$key};
		delete($firstHashRef->{$key});
		$dracula++;
	}
	foreach my $key (keys %secondTmpHash){
		$firstHashRef->{$key} = $secondTmpHash{$key};
		delete($secondHashRef->{$key});
		$dracula++;
	}
	return $dracula;
}

sub functionM : Function(CODE) {
	my $codeRef = shift;
	return $codeRef->( 1, 3 );
}

sub functionN : Function(CODE, CODE) {
	my $codeRef = shift;
	my $otherCodeRef = shift;
	return $codeRef->( 1, $otherCodeRef->( 3, 2 ));
}

sub functionO : Function( TestClass ) {
	my $object = shift;
	return $object->number(1);
}

sub functionP : Function( TestClass, OtherTestClass ) {
	my ($object1, $object2) = @_;
	return $object2->number($object1->number(1));
}

sub functionQ : Function( list ) {
	my @numbers = @_;
	my $tot = 0;
	foreach my $number (@numbers) {
		$tot += $number;
	}
	return $tot;
}

sub functionR : Function( list Scalar ) {
	# error to define anything like the above.
}

sub functionS : Function( Scalar, list ) {
	my $operation = shift;
	my @numbers = @_;
	my $tot = 0;
	if($operation eq '+') {
		foreach my $number (@numbers) {
			$tot += $number;
		}
	} else {
		$tot = 10;
		foreach my $number (@numbers) {
			$tot -= $number;
		}
	}
	return $tot;
}

# this is used to test the other argument with Scalars
sub functionT :Function( other ) {
	my $thingy = shift;
	if(ref($thingy)) {
		return ucfirst(lc(ref($thingy)));
	} else {
		if($thingy =~ /\d+\.?\d*/){
			# it's a number
			return 'Number';
		} else {
			# it's a string
			return 'String';
		}
	}
}

sub functionW :Function( o Scalar ){
	my $option = shift;
	if(defined($option)) {
		return 1;
	} else {
		return -1;
	}
}

sub functionX :Function( Scalar o list ){
	my $operation = shift;
	my $tot = 0;
	if($operation eq '+') {
		foreach my $number (@_) {
			$tot += $number;
		}
	}elsif($operation eq '-') {
		foreach my $number (@_) {
			$tot -= $number;
		}
	}elsif($operation eq '*') {
		$tot = 1;
		foreach my $number (@_) {
			$tot *= $number;
		}		
	}
	return $tot;
}

sub functionY :Function( o scalar scalar) {
	my $opt1 = shift;
	my $opt2 = shift;
	if(scalar($opt1)){
		return 1;
	} elsif(scalar($opt2)){
		return 2;
	}
	return 0;
}
1;

# used for the Class Name Argument tests
package TestClass;
use strict;
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
				number => 0,
			   };
	bless($self, $class);
}
sub number {
	my $self = shift;
	if(scalar(@_)) {
		return $self->{number} += $_[0];
	} else {
		return $self->{number};
	}
}

1;

# used for the Class Name Argument tests
package OtherTestClass;
use strict;
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
				number => 1,
			   };
	bless($self, $class);
}
sub number {
	my $self = shift;
	if(scalar(@_)) {
		return $self->{number} *= $_[0];
	} else {
		return $self->{number};
	}
}

1;

package main;

									  # always use these:
use strict;
use warnings qw{all};
use Test::SimpleUnit qw{:functions};  #}


Test::SimpleUnit::AutoskipFailedSetup(1);

{
	eval { require Attribute::Method::Typeable; };
}

my $evalError = $@;
my $result = 0;
my ($testObject, $otherTestObject);

my @testSuite = (

				 # Setup function
				 {
				  name => 'setup',
				  func => sub {
					  $result = 0;
					  $testObject = TestClass->new;
					  $otherTestObject = OtherTestClass->new;
				  },
				 },

				 # Teardown function
				 {
				  name => 'teardown',
				  func => sub {
					  $testObject = undef;
					  $otherTestObject = undef;
				  },
				 },

				 {
				  name => 'File Loading',
				  test => sub {
					  assertNot( $evalError, "Failed to load file.");
				  },
				 },

				 {
				  name => 'Function Attribute',
				  test => sub {
					  # test functionA
					  assertException( sub {
										   $result = TestPackage::functionA( 1 );
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionA();
										 });
					  assert( $result );
					  # test functionB
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionB( 'fooberries' );
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionB();
										 });
					  assert( $result );
				  },
				 },

				 {
				  name => 'scalar Argument',
				  test => sub {
					  # test failure conditions first.
					  assertException( sub {
										   $result = TestPackage::scalarA( [] );
									   },
									   "Didn't throw Exception::ParamError");
					  my $thingy = 'foo';
					  assertException( sub {
										   $result = TestPackage::scalarA( \$thingy );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::scalarA( );
									   },
									   "Didn't throw Exception::ParamError");
					  # then test success.
					  assertNoException( sub {
											 $result = TestPackage::scalarA('Hello.');
										 });
					  assert($result eq 'Hello.');
					  assertNoException( sub {
											 $result = TestPackage::scalarA(23);
										 });
					  assert($result eq '23');
				  },
				 },

				 {
				  name => 'literal Argument',
				  test => sub {
					  # test failure conditions first.
					  assertException( sub {
										   $result = TestPackage::literalA( [] );
									   },
									   "Didn't throw Exception::ParamError");
					  my $thingy = 'foo';
					  assertException( sub {
										   $result = TestPackage::literalA( \$thingy );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::literalA( );
									   },
									   "Didn't throw Exception::ParamError");
					  # then test success.
					  assertNoException( sub {
											 $result = TestPackage::literalA('Hello.');
										 });
					  assert($result eq 'Hello.');
					  assertNoException( sub {
											 $result = TestPackage::literalA(23);
										 });
					  assert($result eq '23');
				  },
				 },

				 {
				  name => 'whole Argument',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::wholeA( );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::wholeA( {} );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::wholeA( 'cabbage' );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::wholeA( 1.11234 );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::wholeA( 0 );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::wholeA( -5 );
									   },
									   "Didn't throw Exception::ParamError");
					  assertNoException( sub {
											 $result = TestPackage::wholeA( 1 );
										 });
					  assert($result == 2);
				  },
				 },

				 {
				  name => 'integer Argument',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::integerA( );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::integerA( {} );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::integerA( 'cabbage' );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::integerA( 1.11234 );
									   },
									   "Didn't throw Exception::ParamError");
					  assertNoException( sub {
											 $result = TestPackage::integerA( 1 );
										 });
					  assert($result == 2);
					  assertNoException( sub {
											 $result = TestPackage::integerA( 0 );
										 });
					  assert($result == 1);
					  assertNoException( sub {
											 $result = TestPackage::integerA( -1 );
										 });
					  assert($result == 0);
				  },
				 },

				 {
				  name => 'real Argument',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::realA( );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::realA( {} );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::realA( 'cabbage' );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::realA( 1.23e99 );
									   },
									   "Didn't throw Exception::ParamError");
					  assertNoException( sub {
											 $result = TestPackage::realA( 1.1 );
										 });
					  assert($result == 2.1);
 					  assertNoException( sub {
 											 $result = TestPackage::realA( 0.1 );
 										 });
 					  assert($result == 1.1);
 					  assertNoException( sub {
 											 $result = TestPackage::realA( -1.1 );
 										 });
 					  assert($result eq '-0.1');
				  },
				 },

				 {
				  name => 'decimal Argument',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::decimalA( );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::decimalA( {} );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::decimalA( 'cabbage' );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::decimalA( 1.23e99  );
									   },
									   "Didn't throw Exception::ParamError");
					  assertNoException( sub {
											 $result = TestPackage::decimalA( 1.1 );
										 });
					  assert($result == 2.1);
 					  assertNoException( sub {
 											 $result = TestPackage::decimalA( 0.1 );
 										 });
 					  assert($result == 1.1);
 					  assertNoException( sub {
 											 $result = TestPackage::decimalA( -1.1 );
 										 });
 					  assert($result eq '-0.1');
				  },
				 },

				 {
				  name => 'float Argument',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::floatA( );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::floatA( {} );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::floatA( 'cabbage' );
									   },
									   "Didn't throw Exception::ParamError");
					  assertNoException( sub {
											 $result = TestPackage::floatA( 1.1 );
										 });
					  assert($result == 2.1);
 					  assertNoException( sub {
 											 $result = TestPackage::floatA( 0.1 );
 										 });
 					  assert($result == 1.1);
 					  assertNoException( sub {
 											 $result = TestPackage::floatA( -1.1 );
 										 });
 					  assert($result eq '-0.1');
 					  assertNoException( sub {
 											 $result = TestPackage::floatA( 1.23e99 );
 										 });
					  assert($result == 1.23e99);
				  },
				 },

				 {
				  name => 'character Argument',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::characterA( );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::characterA( [] );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::characterA( 'foo' );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::characterA( 22 );
									   },
									   "Didn't throw Exception::ParamError");
 					  assertNoException( sub {
 											 $result = TestPackage::characterA( 'a' );
 										 });
					  assert($result == 1);
 					  assertNoException( sub {
 											 $result = TestPackage::characterA( 2 );
 										 });
					  assert($result == 1);
 					  assertNoException( sub {
 											 $result = TestPackage::characterA( "q" );
 										 });
					  assert($result == 2);
				  },
				 },

				 {
				  name => 'char Argument',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::charA( );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::charA( [] );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::charA( 'foo' );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::charA( 22 );
									   },
									   "Didn't throw Exception::ParamError");
 					  assertNoException( sub {
 											 $result = TestPackage::charA( 'a' );
 										 });
					  assert($result == 1);
 					  assertNoException( sub {
 											 $result = TestPackage::charA( 2 );
 										 });
					  assert($result == 1);
 					  assertNoException( sub {
 											 $result = TestPackage::charA( "q" );
 										 });
					  assert($result == 2);
				  },
				 },

				 {
				  name => 'string Argument',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::stringA( );
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::stringA([]);
									   },
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::stringA( sub {print "foo";} );
									   },
									   "Didn't throw Exception::ParamError");
 					  assertNoException( sub {
 											 $result = TestPackage::stringA( 'foo' );
 										 });
					  assert($result eq 'Hello foo');
 					  assertNoException( sub {
 											 $result = TestPackage::stringA( 'q' );
 										 });
					  assert($result eq 'Hello q');
 					  assertNoException( sub {
 											 $result = TestPackage::stringA( 2 );
 										 });
					  assert($result eq 'Hello 2');
 					  assertNoException( sub {
 											 $result = TestPackage::stringA( 1.23e99 );
 										 });
					  assert($result eq 'Hello 1.23e+99');
 					  assertNoException( sub {
 											 $result = TestPackage::stringA( 1 + 1 );
 										 });
					  assert($result eq 'Hello 2');
				  },
				 },

				 {
				  name => 'vector Argument',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::vectorA();
									   },
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::vectorA(1);
										 });
					  assert($result == 1);
					  assertNoException( sub {
											 $result = TestPackage::vectorA(1,1,2,3,5);
										 });
					  assert($result);
					  assert($result == 12);
					  assertNoException( sub {
											 $result = TestPackage::vectorA(1,2,3,4,5);
										 });
					  assert($result);
					  assert($result == 15);
				  },
				 },

				 {
				  name => 'Scalar Argument',
				  test => sub {
					  # test functionC
					  assertException( sub {
										   $result = TestPackage::functionC();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionC( 2 );
										 });
					  assert( $result );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionC( 1 );
										 });
					  assertNot( $result );
					  # test functionD
					  $result = '';					  
					  assertException( sub {
										   $result = TestPackage::functionD(['apple', 'banana', 'orange']);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = '';
					  assertNoException( sub {
											 $result = TestPackage::functionD( "Hello" );
										 });
					  assert( $result eq 'Hello world.' );
					  $result = '';
					  assertNoException( sub {
											 $result = TestPackage::functionD( 1 );
										 });
					  assert( $result eq '1 world.' );
					  $result = '';
					  assertNoException( sub {
											 $result = TestPackage::functionD( '' );
										 });
					  assert( $result eq ' world.' );
					  # test functionE
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionE({'fred'=>'flintstone', 'barney'=>'rubble'});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  my $number = 2;
					  assertNoException( sub {
											 $result = TestPackage::functionE( \$number );
										 });
					  assert( $number == $result );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionE( \$number );
										 }); 
					  assertNot( $number );
					  assertNot( $result );
					  # test functionF
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionF(sub { print "hello world.\n";});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionF();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionF(1);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionF(1,2,3);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionF(1,1);
										 });
					  assert( $result == 2);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionF(1,-1);
										 });
					  assertNot( $result );
					  # test functionG
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionG(sub { print "hello world.\n";});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionG();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionG(1);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionG(1,2,3);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionG(1,1);
										 });
					  assert( $result == 2);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionG(1,-1);
										 });
					  assertNot( $result );
					  # test functionH
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionH();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionH(1);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionH(1,2);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionH(1,2,3,4);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionH(1,1,0);
										 });
					  assert( $result == 2);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionH(0,1,-1);
										 });
					  assertNot( $result );
				  },
				 },

				 {
				  name => 'ARRAY Argument',
				  test => sub {
					  # test functionI
					  assertException( sub {
										   $result = TestPackage::functionI();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionI(1);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionI('blah');
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionI(\$result);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionI({'fred'=>'flintstone', 'barney'=>'rubble'});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionI(sub {print "hello world\n";});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot( $result );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionI( [0,1,2,3] );
										 });
					  assert( $result );
					  assert( $result == 4 );
					  my @array = (0,1,2,3);
					  assertNoException( sub {
											 $result = TestPackage::functionI( \@array );
										 });
					  assert( $result );
					  assert( $result == 4 );
					  assert( $array[0] == 1);
					  assert( $array[1] == 2);
					  assert( $array[2] == 3);
					  assert( $array[3] == 4);
					  # test functionJ
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionJ();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionJ([1,2,3]);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionJ([1,3,4],[],[2,2,2,3]);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionJ([],{},[]);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  my @array1 = ('frog', 'toad');
					  my @array2 = ('mouse', 'rat');
					  my @array3 = ('dog', 'wolf');
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionJ(@array1, @array2);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionJ(\@array1, \@array2, \@array3);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionJ( \@array1, ['salamander'] );
										 });
					  assert($result);
					  assert($array1[0] eq 'frog');
					  assert($array1[1] eq 'toad');
					  assert($array1[2] eq 'salamander');
					  assertNoException( sub {
											 $result = TestPackage::functionJ( \@array2, \@array3 );
										 });
					  assert($result);
					  assert($array2[0] eq 'mouse');
					  assert($array2[1] eq 'rat');
					  assert($array2[2] eq 'dog');
					  assert($array2[3] eq 'wolf');
					  assert($array3[0] eq $array2[0]);
					  assert($array3[1] eq $array2[1]);
					  assert($array3[2] eq $array2[2]);
					  assert($array3[3] eq $array2[3]);
				  },
				 },

				 {
				  name => 'HASH Argument',
				  test => sub {
					  # test functionK
					  assertException( sub {
										   $result = TestPackage::functionK();
									   }, 
									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionK(1);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionK('blah');
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionK(\$result);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionK( [0,1,2,3]);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionK(sub {print "hello world\n";});
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertNoException( sub {
  											 $result = TestPackage::functionK({'fred'=>'flintstone', 'barney'=>'rubble'});
  										 });
  					  assert( $result );
  					  assert( $result->{flintstone} eq 'fred' );
  					  assert( $result->{rubble} eq 'barney' );
  					  my %hash = (23=>'skiddo', 88=>'keys', 22=>'catch');
  					  assertNoException( sub {
  											 $result = TestPackage::functionK( \%hash );
  										 });
  					  assert( $result );
					  assert( $result->{skiddo} eq $hash{skiddo} );
					  assert( $result->{'keys'} eq $hash{'keys'} );
					  assert( $result->{'catch'} eq $hash{'catch'} );
					  assert( $hash{23} eq 'skiddo' );
					  assert( $hash{22} eq 'catch' );
					  assert( $hash{88} eq 'keys' );					  
					  # test functionL
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionL();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionL({});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionL({},{},{});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionL([],{});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  my %hash1 = ('frog', 'toad');
					  my %hash2 = ('mouse', 'rat');
					  my %hash3 = ('dog', 'wolf');
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionL(%hash1, %hash2);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionL(\%hash1, \%hash2, \%hash3);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionL(\%hash1, \%hash2);
										 });
					  assert($result);
					  assert($result == 2);
					  assert( exists $hash1{mouse} );
					  assert( $hash1{mouse} eq 'rat');
					  assert( exists( $hash2{frog}));
					  assert( $hash2{frog} eq 'toad');
				  },
				 },

				 {
				  name => 'CODE Argument',
				  test => sub {
					  # test functionM
					  assertException( sub {
										   $result = TestPackage::functionM();
									   }, 
									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionM(1);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionM('blah');
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionM(\$result);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionM( [0,1,2,3]);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionM({'fred'=>'flintstone', 'barney'=>'rubble'});
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionM( sub { $_[0] + $_[1]; } );
											 });
					  assert($result);
					  assert($result == 4);
					  # test functionN
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionN();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionN(sub {print "hello world\n";});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionN(sub {1;},sub {0;},sub {3;});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionN(sub {2;},{});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  my $codeRef1 = sub {$_[0] + $_[1];};
					  my $codeRef2 = sub {$_[0] * $_[1];};
					  my $codeRef3 = sub {return 2;};
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionN(sub {}, $codeRef1, $codeRef2);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionN($codeRef1, $codeRef2, $codeRef3);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionN( $codeRef1, $codeRef2 );
										 });
					  assert($result);
					  assert($result == 7);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionN( $codeRef2, $codeRef1 );
										 });
					  assert($result);
					  assert($result == 5);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionN( $codeRef1, $codeRef3 );
										 });
					  assert($result);
					  assert($result == 3);
				  },
				 },

				 {
				  name => 'Class Name Argument',
				  test => sub {
					  # test functionO
					  assertException( sub {
										   $result = TestPackage::functionO();
									   }, 
									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionO(1);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionO('blah');
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionO(\$result);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionO( [0,1,2,3]);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionO({'fred'=>'flintstone', 'barney'=>'rubble'});
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionO(sub {print "hello world\n";});
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
  					  assertException( sub {
  										   $result = TestPackage::functionO($otherTestObject);
  									   }, 
  									   "Didn't throw Exception::ParamError");
  					  assertNot( $result );
  					  $result = 0;
					  assertNoException( sub {
  										   $result = TestPackage::functionO($testObject);
										 });
					  assert($result);
					  assert($result == 1);
					  # test functionP
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionP();
									   },
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionP($testObject);
									   },
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionP($otherTestObject);
									   },
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionP($otherTestObject, $testObject);
									   },
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  my $object = TestClass->new;
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionP($testObject, $otherTestObject, $object);
									   },
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionP(TestClass->new(), OtherTestClass->new());
										 });
					  assert($result);
					  assert($result == 1);
				  },
				 },

				 {
				  name => 'list Argument',
				  test => sub {
					  # test functionQ
					  assertException( sub {
										   $result = TestPackage::functionQ();
									   },
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionQ(1,1,2,3,5);
										 });
					  assert($result);
					  assert($result == 12);
					  assertNoException( sub {
											 $result = TestPackage::functionQ(1,2,3,4,5);
										 });
					  assert($result);
					  assert($result == 15);
					  # test functionR
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionR();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::functionR(1,1,2,3,5);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertException( sub {
										   $result = TestPackage::functionR(1,2,3,4,5);
									   }, 
									   "Didn't throw Exception::ParamError");
					  # test functionS
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionS();
									   },
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionS( '+' );
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionS( '+', 1, 1, 2, 3, 5);
										 });
					  assert($result);
					  assert($result == 12);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionS( '-', 1, 1, 2, 3);
										 });
					  assert($result);
					  assert($result == 3);
				  },
				 },

				 {
				  name => 'other Argument',
				  test => sub {
					  # test functionT
					  # there is no way to call it wrong, except with the wrong number of arguments
					  assertException( sub {
										   $result = TestPackage::functionT();
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionT(1,2);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionT(1);
										 });
					  assert( $result );
					  assert( $result eq 'Number' );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionT('foo');
										 });
					  assert( $result );
					  assert( $result eq 'String' );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionT([]);
										 });
					  assert( $result );
					  assert( $result eq 'Array' );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionT({});
										 });
					  assert( $result );
					  assert( $result eq 'Hash' );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionT(sub {});
										 });
					  assert( $result );
					  assert( $result eq 'Code' );
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionT(\$result);
										 });
					  assert( $result );
					  assert( $result eq 'Scalar' );
				  },
				 },

				 {
				  name => 'Optional Arguments',
				  test => sub {
					  assertException( sub {
										   $result = TestPackage::functionW({});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionW([]);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertException( sub {
										   $result = TestPackage::functionW(sub {});
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  					  assertException( sub {
										   $result = TestPackage::functionW(1,1);
									   }, 
									   "Didn't throw Exception::ParamError");
					  assertNot($result);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionW();
										 });
					  assert($result == -1);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionW(1);
										 });
					  assert($result == 1);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionW('Foo');
										 });
					  assert($result == 1);
					  $result = 0;
					  assertNoException( sub {
											 $result = TestPackage::functionW(\$result);
										 });
					  assert($result == 1);
					  # test functionX
# 					  $result = 0;
# 					  assertException( sub {
# 										   $result = TestPackage::functionX();
# 									   }, 
# 									   "Didn't throw Exception::ParamError");
# 					  assertNot($result);
# 					  $result = 0;
#   					  assertException( sub {
#   										   $result = TestPackage::functionX([]);
#   									   }, 
#   									   "Didn't throw Exception::ParamError");
#   					  assertNot($result);
#   					  $result = 0;
#   					  assertException( sub {
#   										   $result = TestPackage::functionX({});
#   									   }, 
#   									   "Didn't throw Exception::ParamError");
#   					  assertNot($result);
#   					  $result = 0;
#   					  assertException( sub {
#   										   $result = TestPackage::functionX(sub {});
#   									   }, 
#   									   "Didn't throw Exception::ParamError");
#   					  assertNot($result);
#   					  $result = 0;
#   					  assertException( sub {
#   										   $result = TestPackage::functionX([],1,1,1);
#   									   }, 
#   									   "Didn't throw Exception::ParamError");
#   					  assertNot($result);
#   					  $result = 0;
#   					  assertNoException( sub {
#   											 $result = TestPackage::functionX('+');
#   										 });
# 					  assert($result == 0);
# 					  $result = 0;
# 					  assertNoException( sub {
# 										   $result = TestPackage::functionX('+',1,1,2,3,5);
# 									   }, 
# 									   "Didn't throw Exception::ParamError");
# 					  assert($result == 12);
# 					  $result = 0;
# 					  assertNoException( sub {
# 										   $result = TestPackage::functionX('-',1,1,2,3,5);
# 									   }, 
# 									   "Didn't throw Exception::ParamError");
# 					  assert($result == -12);
# 					  $result = 0;
# 					  assertNoException( sub {
# 										   $result = TestPackage::functionX('*',1,1,2,3,5);
# 									   }, 
# 									   "Didn't throw Exception::ParamError");
# 					  assert($result == 30);
# 					  $result = 0;
# 					  assertNoException( sub {
# 										   $result = TestPackage::functionX('/',1,1,2,3,5);
# 									   }, 
# 									   "Didn't throw Exception::ParamError");
# 					  assert($result == 0);

# 					  # test functionY
# 					  $result = 0;
# 					  assertNoException( sub {
# 											 $result = TestPackage::functionY();
# 									   });
# 					  assertNot($result);
# 					  assertNoException( sub {
# 											 $result = TestPackage::functionY(1);
# 										 });
# 					  assert($result == 1);
				  },
				 },

				);

runTests(@testSuite);

