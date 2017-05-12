#!/usr/bin/perl -w
##############################################################################

=head1 NAME

    Attribute::Method::Typeable - This module implements a series of attribute handler methods for use with function and method argument checking

=head1 SYNOPSIS

    package MyClass;

    use mixin qw{  Attribute::Method::Typeable };

    #or

    use base qw{ Attribute::Method::Typeable };

    sub myMethod :Public( int int ) {
        my $self = shift;
        my ($a, $b) = @_;
        return $a + $b;
    }

    sub otherMethod :Public( OtherClass SomeClass ) {
        my $self = shift;
        my ($obj1, $obj2) = @_;
        # methody stuff here.
    }

    sub privateMethod :Private( scalar, Scalar, SCALAR ) {
        my $self = shift;
        my $literal = shift;
        my $litOrRef = shift;
        my $scalarRef = shift;

        # methody stuff.
    }

    sub protectedMethod :Protected( other ) {
        my $self = shift;
        my $anything = shift;
        # methody stuff.
    }

    sub functiony :Function( ARRAY, CODE, HASH ) {
        # functiony stuff here.
        my ($arrayRef, $codeRef, $hashRef) = @_;
    }

    sub functionz :Function( float ARRAY o list ) {
        my ($arg1, $arg2, @else) = @_;
        $arg2->[0] = $arg1;
        if(scalar(@else)) {}
        # other functiony stuff.
    }

    ### In your code:

    # okay:
    $object->myMethod( 1, 2 );

    # throws an Exception::ParamError exception:
    $object->myMethod( 1, "apple" );

    # also throws an Exception::ParamError exception:
    $object->myMethod( 7 );

    # throws an Exception::MethodError exception:
    myMethod('MyClass', 3, 4 );

    # also throws an Exception::MethodError exception
    # unless it's in MyClass:
    $object->privateMethod( OtherClass->new, SomeClass->new );

    # also throws an Exception::MethodError exception
    # unless it's in MyClass or a subclass of MyClass:
    $object->protectedMethod( $thingy );

=head1 EXPORTS

Nothing by default.

=head1 REQUIRES

perl version 5.8.0, Attribute::Handlers, Data::Types, Test::SimpleUnit, Scalar::Util, Hook::WrapSub, Exception::Class, and optionally the mixin modules.

=head1 DESCRIPTION

This module implements a number of attribute handlers for use in argument checking.
It provides attributes which differentiate between functions, public methods, protected methods, and private methods.
It throws an exception in the case of an incorrect usage.  Basically, these exceptions are meant to alert you of an incorrect calling of your methods or functions.  Use of these attributes is also self-documenting.

=head1 ATTRIBUTES

As these are attributes, they go after the name of the function or method (i.e. subroutine name) but before the first curly brace.  You simply specify the type of the subroutine (kinda like in more strongly typed languages), and any arguments that that subroutine takes.  Below is a description of the available attributes.

=head2 :Function

This attribute specifies that the subroutine is a simple function.  Since it is a function there is no need to verify that the caller has permission to call it, so the only things that are checked are the arguments.  An exception will be thrown if any of the required arguments are missing or if the arguments are of the incorrect type.

=head2 :Constructor

This attribute specifies that the subroutine is a constructor.  This means that it expects as it's first argument either an object or a class.  Any additional arguments to the constructor are also checked.  It is also assumed that a Constructor is Public in nature.

=head2 :Public

This attribute specifies that the subroutine is a public method.  The first thing that is checked is that the first argument to this subroutine is in fact an object of the appropriate class.  The arguments are also checked for validity, but since it is public, the caller is not checked.  An exception is thrown if the first object is missing or not an object of the correct class, or if any of the required arguments are missing or if the arguments are of the incorrect type.

=head2 :Protected

This attribute specifies that the subroutine is a protected method.  An exception is thrown if the first argument to a subroutine specified with this attribute is not an object of the appropriate class.  Next the caller of the method is checked to be sure that it is either the class it was defined in itself or inherits from that class, an exception is thrown otherwise.  Finally, each of the argument types is checked and an exception is thrown if an argument is of the wrong type or is missing if required.

=head2 :Private

This attribute specifies that the subroutine is a private method.  The first argument is checked to be sure that it is an object of the appropriate type, an exception is thrown otherwise.  The second thing that is checked is whether the caller of the method is the class that initially defined it, if not an exception is thrown.  Finally, the arguments are checked for correct type and to be sure that all required arguments are present.

=head2 :Class

This attribute specifies that the subroutine is a class method.  The program expects the first argument to be either the class (or an instance of the class) that it was defined in or a subclass of that class.  Arguments are also checked for validity.

=head2 :Abstract

This attribute specifies that the subroutine is an abstract method.  This means that the method is simply there to define an interface and should never be called directly, if it is an Exception::MethodError will be thrown.

=head2 :Virtual

This attribute is a synonym for :Abstract.

=head1 ARGUMENTS

The arguments to the attributes are specified within parenthesis.  The arguments can be separated either with spaces or with commas.  The case of the argument is important, because the program assumes that certain values in all caps correspond to the standard perl references.  Below is a description of the available argument types.

=head2 whole

This specifies that the argument must be of whole number type, that is it must be a counting number.

=head2 int/integer

This specifies that the argument must be of integer number type, that means it includes zero and negative numbers.

=head2 decimal

This specifies that the argument must be of decimal number type, that is it can contain a decimal point, and be positive or negative.

=head2 real

This specifies that the argument must be of real number type, that is it can contain a decimal point, and be positive or negative.

=head2 float

This specifies that the argument must be of float number type, that is it can contain a decimal point, and be positive or negative, it can also contain an exponential notation.

=head2 char/character

This specifies that the argument must be a single character such as 'q', "r" or 2.

=head2 string

This specifies that the argument must be a string of characters, like 'foo', "bar" or 11234.334.

=head2 scalar/literal

This specifies that the argument can be any literal data, but not a reference.

=head2 Scalar

This specifies that the argument can either be a literal data item or a SCALAR reference.

=head2 SCALAR

This specifies that the argument to the subroutine will be a SCALAR reference.

=head2 ARRAY

This attribute argument indicates that the subroutine thus defined must recieve an array reference as an argument.  For lists or literal arrays, see the list argument.

=head2 HASH

If this attribute argument is used, then the subroutine will accept only a hash reference for an argument in this position.  For lists or literal hashes, see the list argument.

=head2 CODE

The attribute argument CODE signifies that the subroutine will accept a subroutine reference as an argument.

=head2 list/vector

The list attribute argument indicates that the subroutine will accept a series of values of any type.  The list attribute argument must come after all other attribute arguments or an error will be thrown (unfortunately, this error is not currently caught at the time of compilation of the code implementing the method-prototyped attributes).  The list attribute argument should be used when it is desired to pass an array or hash by value instead of by reference.  It can also be used to specify that the subroutine can accept multiple arguments of any type.  The list attribute argument indicates that the subroutine must have at least one argument, but could have nearly any number of arguments (limited by available memory).  If a variable type argument is needed in the middle of stronger typed arguments, the attribute argument 'other' should be used.

=head2 other

By using the attribute argument 'other', the programmer can specify that the type of the argument could be anything.  The other attribute argument indicates that a single argument is desired, for multiple arguments the list attribute argument should be used.

=head2 Class Name

Any class name can be specified as an argument.  If a class name is specified, only arguments of that class, or objects that inherit from that class will be accepted as valid arguments.  This being said, the programmer would be wise to specify the lowest (most specific, least abstract) available subclass that can be used by the subroutine as the argument attribute.

=head2 Optional o

The lowercase 'o' indicates that any following arguments are considered optional.  This can be used in front of any of the actual argument attributes, in fact, it can be used at the start of an attribute argument list to indicate that all of the arguments will be optional to the subroutine (even so, you can still type check them if they are present).  Multiple arguments defined this way must be specified positionally to the subroutine, unless the attribute argument 'other' is used ubiquitously.  In any case, an argument will be considered required and an exception will be thrown if it is missing unless the 'o' attribute argument precedes it.

=head1 EXAMPLES

See SYNOPSIS.

=head1 TODO

Make a simple utility which turns the Attribute Enhanced code into comments for production ready code.

Get the stack trace to start from before the method is called (ie take out all of the Attribute::Method::Typeable calls off the top).

And a syntax for alterations (SomeClass|OtherClass) and lists list(Thingy).

=head1 AUTHOR

Jeremiah Jordan E<lt>jjordan@perlreason.comE<gt>

Copyright (c) 2004, Perl Reason, LLC. All Rights Reserved.

This module is free software. It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

##############################################################################
package Attribute::Method::Typeable;
use strict;
use warnings qw{all};

###############################################################################
###  I N I T I A L I Z A T I O N 
###############################################################################
BEGIN {

    ### Versioning stuff and custom includes
	require 5.006_001;
    use vars qw{$VERSION $RCSID};
  
    $VERSION    = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
    $RCSID      = q$Id: Typeable.pm,v 1.9 2004/10/20 21:37:30 phaedrus Exp $;

	# Ah, blessed...
    use Scalar::Util qw{blessed};

	use Exception::Class ('Exception',
						  'Exception::RuntimeError' => {isa => 'Exception'},
						  'Exception::MethodError' => {isa => 'Exception'},
						  'Exception::ParamError'  => {isa => 'Exception'},
						  );
	# turn on stack tracing
	Exception::Class::Base::Trace(1);

	# for the attributes of course!
    use Attribute::Handlers;
	# to wrap the subroutines that use the attributes.
    use Hook::WrapSub qw( wrap_subs );
	# to check the datatypes easily:
	use Data::Types qw{:is};
	# to make it mixinable with everything if the user has mixin:
	my $mixinLoaded = eval { require mixin::with; return 1; };
	if($mixinLoaded) { mixin::with->import('UNIVERSAL'); }
}


###############################################################################
###  C O N F I G U R A T I O N   ( G L O B A L S )
###############################################################################
use vars qw{};
our $dracula = 1;

###############################################################################
###  P U B L I C   M E T H O D S 
###############################################################################




###############################################################################
###  P R I V A T E   M E T H O D S 
###############################################################################



###############################################################################
###  P U B L I C   F U N C T I O N S 
###############################################################################


###############################################################################
# name: Function
###############################################################################
sub UNIVERSAL::Function :ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

    my @attributes = attributeExtract($data);
    my $before = sub {
		my @arguments = @_;
		argumentCheck( *{$symbol}{NAME}, \@arguments, \@attributes );
    };
	wrap_subs( $before, join('::', $package, *{$symbol}{NAME}));
}

###############################################################################
# name: Abstract
###############################################################################
sub UNIVERSAL::Abstract :ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    my $before = sub {
		my @arguments = @_;
		my $class = shift(@arguments);
		$class ||= '';
		# Abstract (Virtual) methods should not be called directly ever, they should always be overridden.
		throw Exception::MethodError "This is an Abstract method of $class, it should be overridden, not called directly.";
    };
	# if I ever implement return value checker's, this would be an easy one to check.
	wrap_subs( $before, join('::', $package, *{$symbol}{NAME}));
}

###############################################################################
# name: Virtual
###############################################################################
sub UNIVERSAL::Virtual :ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    my $before = sub {
		my @arguments = @_;
		my $class = shift(@arguments);
		$class ||= '';
		# Virtual (Abstract) methods should not be called directly ever, they should always be overridden.
		throw Exception::MethodError "This is a Virtual method of $class, it should be overridden, not called directly.";
    };
	# if I ever implement return value checker's, this would be an easy one to check.
	wrap_subs( $before, join('::', $package, *{$symbol}{NAME}));
}

###############################################################################
# name: Constructor
###############################################################################
sub UNIVERSAL::Constructor :ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

    my @attributes = attributeExtract($data);
    my $before = sub {
		my @arguments = @_;
		my $class = shift(@arguments);
		$class ||= '';
		# if the first argument is not an object or class (i.e. package name), it is not a valid constructor.
		# for some reason I can't get this to work with Guestlist::Parser
		throw Exception::MethodError "This is a constructor, it requires either a class or an object: $class" unless((UNIVERSAL::isa($class, "UNIVERSAL")) && ($class->isa($package)));
		argumentCheck( *{$symbol}{NAME}, \@arguments, \@attributes );
    };
	# if I ever implement return value checker's, this would be an easy one to check.
	wrap_subs( $before, join('::', $package, *{$symbol}{NAME}));
}

###############################################################################
# name: Class
###############################################################################
sub UNIVERSAL::Class :ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

    my @attributes = attributeExtract($data);
    my $before = sub {
		my @arguments = @_;
		my $proto = shift(@arguments);
		my $class = ref($proto) || $proto;
		# It's either the same class or a subclass calling the Class method.
		throw Exception::MethodError "This is a class method" unless ($class->isa( $package ));
		# don't know what to do with class, since it may be a subclass, we can't really check for anything specific.
		argumentCheck( *{$symbol}{NAME}, \@arguments, \@attributes );
    };
	wrap_subs( $before, join('::', $package, *{$symbol}{NAME}));
}

###############################################################################
# name: Public
###############################################################################
sub UNIVERSAL::Public : ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    my @attributes = attributeExtract($data);

    my $before = sub {
		my @arguments = @_;
        _methodCheck( shift(@arguments), $package );
		argumentCheck( *{$symbol}{NAME}, \@arguments, \@attributes);
    };
	wrap_subs( $before, join('::', $package, *{$symbol}{NAME}));
}

###############################################################################
# name: Protected
###############################################################################
sub UNIVERSAL::Protected :ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    my @attributes = attributeExtract($data);

    my $before = sub {
		my @arguments = @_;
		my $object = shift(@arguments);
        _methodCheck( $object, $package );
		# check the caller to see if it's the same class or a subclass.
		throw Exception::MethodError "This is a protected method" unless ($object->isa( $Hook::WrapSub::caller[0] ));
		argumentCheck( *{$symbol}{NAME}, \@arguments, \@attributes);
    };
	wrap_subs( $before, join('::', $package, *{$symbol}{NAME}));
}

###############################################################################
# name: Private
###############################################################################
sub UNIVERSAL::Private :ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    my @attributes = attributeExtract($data);
    my $before = sub {
		my @arguments = @_;
		my $object = shift(@arguments);
        _methodCheck( $object, $package );
		# check the caller to see if it's the same class.
		throw Exception::MethodError "This is a private method" unless ($object->isa( $Hook::WrapSub::caller[0]) && (ref($object) eq $package));
		argumentCheck( *{$symbol}{NAME}, \@arguments, \@attributes);
	};
	wrap_subs( $before, join('::', $package, *{$symbol}{NAME}));
}

### WTF: If I remove this, then Private attributes (or whatever is defined *last*) will not work through mixin.
#sub Throwaway :ATTR(CODE){}

###############################################################################
###  P R I V A T E   F U N C T I O N S 
###############################################################################

sub attributeExtract {
	my $data = shift;
	my @attributes = ();
    if(ref($data) eq 'ARRAY') {
        foreach(@{$data}) {
            push(@attributes, $_) if(scalar(@{$data}));
        }
#		print "a: ",@attributes, "\n" if(scalar(@attributes));
    } elsif(not(ref($data))){
        push(@attributes, split(' ', $data)) if(scalar($data));
    }
	return @attributes;
}

sub _methodCheck {
    my ($object, $class) = @_;
    throw Exception::MethodError unless( blessed($object) && $object->isa($class) );
}

sub argumentCheck {
	my ($subroutine, $argRef, $attRef) = @_;
	my @arguments = @{$argRef};
	my @attributes = @{$attRef};
	# this should now be run with table driven methods:
	my %attributeHandlers = (
							 Scalar		=> 'scalarHandler',
							 scalar		=> 'literalHandler',
							 literal	=> 'literalHandler',
							 whole		=> 'wholeHandler',
							 integer	=> 'integerHandler',
							 int        => 'integerHandler',
							 decimal	=> 'decimalHandler',
							 real		=> 'realHandler',
							 float		=> 'floatHandler',
							 character	=> 'characterHandler',
							 char		=> 'characterHandler',
							 string		=> 'stringHandler',
							 list		=> 'listHandler',
							 vector     => 'listHandler',
							 other		=> 'otherHandler',
							 # SCALAR, ARRAY, HASH, etc. are still supported, but use the default subroutine
							 # which is also the subroutine that handles objects blessed into a specified class.
							);
	my $optional = '';
	if((scalar(@attributes)) and ($attributes[0] eq 'o')) {
		$optional = shift(@attributes);
	}
	if(scalar(@attributes) > 0) { # we have one or more attribute (or more)
		# get it's attribute handler, or the default one.

		# do we have any arguments?
		if(scalar(@arguments)) {
			$arguments[0] = '' unless(defined($arguments[0])); #fix for undefined argument bug.
			my $handlerSub = exists($attributeHandlers{$attributes[0]}) ? $attributeHandlers{$attributes[0]} : 'defaultHandler';
			# call that attribute handler with the argument list.
			no strict 'refs';
			&{$handlerSub}($subroutine, \@arguments, \@attributes, $optional);
		} else { # no arguments.
			throw Exception::ParamError(error => "$subroutine: Argument number $dracula is a required argument of type $attributes[0].\n", show_trace => 1) unless($optional);
		}
	} else { # we don't have any more attributes
		if(scalar(@arguments)){
			throw Exception::ParamError(error => "$subroutine: Too many arguments.\n", show_trace => 1);
		}
	}
	$dracula = 1;
}


# this handler accepts anything that's not a reference
sub literalHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# all we have to check is that the first argument is of the appropriate type:
	throw Exception::ParamError(error => "$sub: Argument number $dracula must be an l-value (literal).\n", show_trace => 1) if(ref($argument));
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles scalar values, any literal value, or scalar reference
sub scalarHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# all we have to check is that the first argument is of the appropriate type:
	if(ref($argument)) {
		throw Exception::ParamError(error => "$sub: Argument number $dracula must be a scalar reference or l-value (literal).\n", show_trace => 1) unless(ref($argument) eq 'SCALAR');
	}
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles just integer values
sub integerHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# all we have to check is that the first argument is of the appropriate type:
	throw Exception::ParamError(error => "$sub: Argument number $dracula must be an integer.\n", show_trace => 1) unless(is_int($argument));
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles float values
sub floatHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# all we have to check is that the first argument is of the appropriate type:
	throw Exception::ParamError(error => "$sub: Argument number $dracula must be a float.\n", show_trace => 1) unless(is_float($argument));
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles whole values
sub wholeHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# all we have to check is that the first argument is of the appropriate type:
	throw Exception::ParamError(error => "$sub: Argument number $dracula must be a whole number.\n", show_trace => 1) unless(is_whole($argument));
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles decimal values
sub decimalHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# all we have to check is that the first argument is of the appropriate type:
	throw Exception::ParamError(error => "$sub: Argument number $dracula must be a decimal number.\n", show_trace => 1) unless(is_decimal($argument));
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles real values
sub realHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# all we have to check is that the first argument is of the appropriate type:
	throw Exception::ParamError(error => "$sub: Argument number $dracula must be a real number.\n", show_trace => 1) unless(is_real($argument));
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles character values
sub characterHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# all we have to check is that the first argument is of the appropriate type:
	throw Exception::ParamError(error => "$sub: Argument number $dracula must be a single character.\n", show_trace => 1) unless((is_string($argument)) and ($argument =~ /^.$/));
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles string values
sub stringHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# all we have to check is that the first argument is of the appropriate type:
	throw Exception::ParamError(error => "$sub: Argument number $dracula must be a string.\n", show_trace => 1) unless(is_string($argument));
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles list values (of anything right now)
sub listHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	# the list handler is just like the other handler (for now) except that it slurps up all of the arguments.
	throw Exception::RuntimeError(error => "$sub: Improper use of list argument definition, list must come at the end of all other arguments\n", show_trace => 1) if(scalar(@{$attrRef}));
	$dracula = 1;
}

# this handles any type of value
sub otherHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# other can be of any type.
	# put $opt back on the front if it's there:
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

# this handles references and objects (blessed references)
sub defaultHandler {
	my ($sub, $argRef, $attrRef, $opt) = @_;
	my $attribute = shift(@{$attrRef});
	my $argument = shift(@{$argRef});
	# this handles the case where the attribute is some kind of reference (either blessed, or not).
	if(blessed($argument)) { # it's an object.
		throw Exception::ParamError(error => "$sub: Argument number $dracula must be an instance of class $attribute or a subclass\n", show_trace => 1) unless( $argument->isa( $attribute ) );
	} else { # it's a normal reference
		throw Exception::ParamError(error => "$sub: Argument number $dracula must be a reference of type $attribute\n", show_trace => 1) unless( ref($argument) eq $attribute );
	}
	unshift(@{$attrRef}, $opt) if($opt);
	$dracula++;
	argumentCheck($sub, $argRef, $attrRef);
}

###############################################################################
###  P A C K A G E   A N D   O B J E C T   D E S T R U C T O R S 
###############################################################################


### The package return value (required)
1;


###############################################################################
###  D O C U M E N T A T I O N 
###############################################################################

=cut
