# generate and execute access permutations
package Class::Declare::Attributes::Test;

use strict;
use File::Spec::Functions;

use base qw( Class::Declare::Attributes );
use vars qw( $REVISION $VERSION );
             $REVISION	= '$Revision: 1515 $';
             $VERSION   = '0.02';

=head1 NAME

Class::Declare::Attributes::Test - simplify the generation of method/attribute
tests.

=head1 SYNOPSIS

  use Class::Declare::Attributes::Test qw( :constants );

  # set the type of method/attribute test
  #    i.e. class, public, private, etc
  my $type  = 'static';

  # define the tests
  #    - tests are created as bitmaps representing the context, the
  #      target, the test and the expected outcome
  my $tests = [ CTX_CLASS | TGT_DERIVED | TST_READ | DIE ,
                ... ];

  # create the test object
  my $test  = Class::Declare::Attributes::Test->new( type  => $type  ,
                                                     tests => $tests ,
                                                     check => 1      );

  # run the tests
     $test->run;

=cut

#
# define the testing constants
#

use constant	_CLASS				      => ( 1 << 0 );
use constant	_DERIVED			      => ( 1 << 1 );
use constant	_UNRELATED		    	=> ( 1 << 2 );
use constant	_PARENT   		    	=> ( 1 << 3 );

# are we dealing with a class or instance?
use constant	_INSTANCE			      => ( 1 << 4 );
use constant	_IS_INSTANCE	    	=> sub {   $_[ 0 ] >> 4 };

# define the context and target macros
use constant	_CONTEXT			      => sub {   $_[ 0 ] << 0 };
use constant	_TARGET			      	=> sub {   $_[ 0 ] << 5 };

# extract the context, context and target from a given bitmap
use constant	_MASK				        => ( ( 1 << 5 ) - 1 );
use constant	_GET_CONTEXT		    => sub { ( $_[ 0 ] >> 0 ) & _MASK };
use constant	_GET_TARGET			    => sub { ( $_[ 0 ] >> 5 ) & _MASK };

# define the test constants
use constant	_TEST_ACCESS		    => ( 1 << 0 );
use constant	_TEST_READ			    => ( 1 << 1 );
use constant	_TEST_WRITE_LVALUE	=> ( 1 << 2 );
use constant	_TEST_WRITE_ARG		  => ( 1 << 3 );
use constant	_TEST_WRITE			    => (   _TEST_WRITE_LVALUE
            	            		         | _TEST_WRITE_ARG    );
use constant	_TEST_ALL			      => (   _TEST_ACCESS
            	         			           | _TEST_READ
            	         			           | _TEST_WRITE        );

use constant	_TEST				        => sub {   $_[ 0 ] << 10 };
use constant	_GET_TEST		       	=> sub { ( $_[ 0 ] >> 10 ) & _MASK };

# are we dealing in the method call or the attribute
use constant	_ATTRIBUTE	    		=> ( 1 << 0 );
use constant	_METHOD			      	=> 0;

# define the constants for the focus of the test
use constant	_FOCUS			      	=> sub {   $_[ 0 ] << 14 };
use constant	_GET_FOCUS	    		=> sub { ( $_[ 0 ] >> 14 ) & 1 };

# define the expected result of the test
use constant	_DIE 				        =>   0;
use constant	_LIVE				        => ( 1 << 0 );
use constant	_RESULT			      	=> sub {   $_[ 0 ] << 15 };
use constant	_GET_RESULT	    		=> sub { ( $_[ 0 ] >> 15 ) & 1 };

# define the context macros to be exported
use constant	CTX_CLASS		   	    => _CONTEXT->(             _CLASS     );
use constant	CTX_DERIVED			    => _CONTEXT->(             _DERIVED   );
use constant	CTX_UNRELATED		    => _CONTEXT->(             _UNRELATED );
use constant	CTX_PARENT   		    => _CONTEXT->(             _PARENT    );
use constant	CTX_INSTANCE		    => _CONTEXT->( _INSTANCE | _CLASS     );
use constant	CTX_INHERITED		    => _CONTEXT->( _INSTANCE | _DERIVED   );
use constant	CTX_FOREIGN			    => _CONTEXT->( _INSTANCE | _UNRELATED );
use constant	CTX_SUPER  			    => _CONTEXT->( _INSTANCE | _PARENT    );

# define the target macros to be exported
use constant	TGT_CLASS		  	    =>  _TARGET->(             _CLASS     );
use constant	TGT_DERIVED			    =>  _TARGET->(             _DERIVED   );
use constant	TGT_UNRELATED		    =>  _TARGET->(             _UNRELATED );
use constant	TGT_PARENT   		    =>  _TARGET->(             _PARENT    );
use constant	TGT_INSTANCE		    =>  _TARGET->( _INSTANCE | _CLASS     );
use constant	TGT_INHERITED		    =>  _TARGET->( _INSTANCE | _DERIVED   );
use constant	TGT_FOREIGN			    =>  _TARGET->( _INSTANCE | _UNRELATED );
use constant	TGT_SUPER  			    =>  _TARGET->( _INSTANCE | _PARENT    );

# define the test macros to be exported
use constant	TST_ACCESS	  		  =>    _TEST->( _TEST_ACCESS           );
use constant	TST_READ		    	  =>    _TEST->( _TEST_READ             );
use constant	TST_WRITE_LVALUE	  =>    _TEST->( _TEST_WRITE_LVALUE     );
use constant	TST_WRITE_ARG 		  =>    _TEST->( _TEST_WRITE_ARG        );
use constant	TST_WRITE		    	  =>    _TEST->( _TEST_WRITE            );
use constant	TST_ALL			    	  =>    _TEST->( _TEST_ALL              );

# define the result macros to be exported
use constant	LIVE				        =>  _RESULT->( _LIVE                  );
use constant	DIE					        =>  _RESULT->( _DIE                   );

# define the focus macros for export
use constant	ATTRIBUTE			      =>   _FOCUS->( _ATTRIBUTE             );
use constant	METHOD				      =>   _FOCUS->( _METHOD                );


# define the export targets
use vars qw/ @EXPORT_OK %EXPORT_TAGS /;

# define attribute and method default values
use constant	DEFAULT_ATTRIBUTE	  => rand time;
use constant	DEFAULT_METHOD		  => rand time;


# define the accessors we'll use in the test classes
#    - these accessors ensure we have the correct context for all of
#      the test cases
use constant	ACCESSORS			      => <<__EODfN__;

#
# We need to test to see whether we can access attributes and methods from
# within and outside of a defining package. To facilitate this, we provide
# accessor methods
#


# create local attribute accessor
sub get
{
	# will be honoured as either a class or instance method
	my	\$self		= __PACKAGE__->class( shift );
	my	\$target	= shift || \$self;
  		\$target->attribute
} # get()


# create local method accessor
sub call
{
	# will be honoured as either a class or instance method
	my	\$self		= __PACKAGE__->class( shift );
	my	\$target	= shift || \$self;
  		\$target->method;
} # call()


#
# We need to check to see if attribute assignments hold (i.e. the values are
# actually assigned).
#

# lvalue assignment test
sub cmp_lvalue
{
	my	\$self		= __PACKAGE__->class( shift );
	my	\$target	= shift || \$self;
	my	\$rand		= rand time;
  		\$target->lvalue( \$rand );
  	( \$target->attribute == \$rand );
} # cmp_lvalue()


# argument assignment test
sub cmp_argument
{
	my	\$self		= __PACKAGE__->class( shift );
	my	\$target	= shift || \$self;
	my	\$rand		= rand time;
  		\$target->argument( \$rand );
  	( \$target->attribute == \$rand );
} # cmp_argument()

__EODfN__


=head1 DESCRIPTION

B<Class::Declare::Attributes::Test> simplifies the generation of invocation
tests for B<Class::Declare::Attributes>. Tests are defined as a series
of bitmaps, specifying the context for the test (i.e. environment for
the invocation of the calls), the target of the test (i.e. the object or
class the method or attributes will be called on), the test to perform
(e.g. access, read, write, etc), and the expected result (is the test
supposed to live or die). The tests are executed for a type of attribute
or method, such as a C<class> or C<private> attributes and methods.

=head2 Constants

The constants used to define the tests may be imported into the current
namespace by using one of the following tags:

=over 4

=item C<:contexts>

Define all the different contexts. This defines where the method/attribute
invocations will occur:

=over 4

=item C<CTX_CLASS>

The context is the class in which the method/attribute are defined.

=item C<CTX_DERIVED>

The context is a class that inherits from the class defining the method
and attribute.

=item C<CTX_UNRELATED>

The context is a class unrelated to the class defining the method/attribute.

=item C<CTX_INSTANCE>

The context is an instance of the class defining the attribute/method.

=item C<CTX_INHERITED>

The context is an instance of a class derived from the class defining the
attribute and method.

=item C<CTX_FOREIGN>

The context is an instance of a class unrelated to the class defining the
attribute/method.

=back


=item C<:targets>

These constants define the class or object on which the attribute and method
invocations will be made. They are the same as the context constants.

=over 4

=item C<TGT_CLASS>

=item C<TGT_DERIVED>

=item C<TGT_UNRELATED>

=item C<TGT_INSTANCE>

=item C<TGT_INHERITED>

=item C<TGT_FOREIGN>

=back


=item C<:tests>

These constants define the different tests to perform:

=over 4

=item C<TST_ACCESS>

Test to see if we can access the method or attribute.

=item C<TST_READ>

Test to see if we can read the result of the method or attribute. The ACCESS
test essentially tests to see if we can invoke the method or attribute
accessor, while the READ test makes sure the values we extract are correct.

=item C<TST_WRITE_LVALUE>

Test to see if we can write to the attribute as an LVALUE. Note that we only
really need to test attributes, since testing LVALUE methods would be the
same as testing Perl's support for LVALLUEs.

=item C<TST_WRITE_ARG>

Test to see if we can write values to an attribute by passing the new value
as an argument to the attribute accessor.

=item C<TST_WRITE>

This is the same as C<TST_WRITE_LVALUE>|C<TST_WRITE_ARG>.

=back


=item C<:results>

These constants define whether the given test is expected to live or die.

=over 4

=item C<LIVE>

=item C<DIE>

=back


=item C<:focus>

These constants define the focus of the test, i.e. are we testing an attribute
or a method?

=over 4

=item C<ATTRIBUTE>

=item C<METHOD>

=back


=item C<:constants>

Export all the constants into the current namespace.

=back

To create a test, OR the constants together to form a test bitmap. A test
must have a I<context>, a I<target>, a I<test>, a I<focus>, and an expected
I<result>. See the C<class.t>, C<public.t>, etc test scripts for examples.

=cut

{
	no strict 'refs';

	# get the list of symbols to export
	my	@symbols	= keys %{ __PACKAGE__ . '::' };
	my	@context	= grep { /^CTX_/o } @symbols;
	my	@target		= grep { /^TGT_/o } @symbols;
	my	@test		  = grep { /^TST_/o } @symbols;
	my	@focus		= qw( ATTRIBUTE METHOD );
	my	@result		= qw( LIVE      DIE    );

	# export the various symbols
	@EXPORT_OK		= ( @context , @target , @test ,
	          		    @result  , @focus  );
	%EXPORT_TAGS	= ( contexts  => \@context   ,
	            	    targets   => \@target    ,
	            	    tests     => \@test      ,
	            	    results   => \@result    ,
	            	    focus     => \@focus      ,
	            	    constants => \@EXPORT_OK );
}


# load the test modules
#  - NB: the number of tests is determined at run-time
use Test::More			qw( no_plan );
use Test::Exception;

=head2 Methods

=over 4

=item B<new(> type => I<type> , tests => I<tests>
              [ , check => I<boolean> ] B<)>

Create a new test object. I<type> specifies the type of attribute/method to
test, which must be one of the following:

=over 4

=item C<class>

=item C<static>

=item C<restricted>

=item C<public>

=item C<private>

=item C<protected>

=back

I<tests> is a reference to an array of test bitmaps defining the tests
to perform. See the C<class>, C<static>, C<restricted>, C<public>, C<private>,
C<protected> and C<strict> test files.

The I<check> attribute may be used to turn strict access checking on and
off for a particular set of tests. I<check> defaults to true, giving strict
access checking, while a false value will turn access checking off.

=cut

# define the Permute class
__PACKAGE__->declare(

	# public attributes
	public  => { type      => undef ,	  # type of test (public, private, etc)
	             tests     => undef ,	  # the tests hash
	             check     => undef } ,	# turn on strict checking

	# private attributes for the Permute class
	private => { base      => undef ,	  # the base class
	             derived   => undef ,	  # the derived class
	             unrelated => undef ,	  # the unrelated class
	             parent    => undef ,	  # the parent class
	             instance  => undef ,	  # the base class instance
	             inherited => undef ,	  # the derived class instance
	             foreign   => undef ,	  # the unrelated class instance
	             super     => undef } ,	# the parent class instance

	# specify the initialisation routine
	init    => sub {
		my	$self	  = __PACKAGE__->public( shift );
		my	$class	= ref( $self );

		# ensure the test type and outcomes hash have been define
		warn $class . ": 'type' attribute must be defined\n"
			and return undef		unless ( $self->type  );
		warn $class . ": 'tests' attribute must be defined\n"
			and return undef		unless ( $self->tests );

		# make sure the type is understood
		( grep { $self->type eq $_ } qw( class  static  restricted 
		                                 public private protected  
                                                    abstract   ) )
			 or warn $class . ': unknown type "' . $self->type . '"'
			and return undef;

		# make sure we have a lists of test
		( ref( $self->tests ) eq 'ARRAY' )
			 or warn $class . ': array of tests expected'
			and return undef;

		# create the base, derived and unrelated class names
		my	$type				        = $self->type;
			  $self->base			    = join '::' , __PACKAGE__ , ucfirst( $type );
			  $self->derived		  = join '::' , $self->base , 'Derived';
			  $self->unrelated	  = join '::' , $self->base , 'Unrelated';
			  $self->parent       = join '::' , $self->base , 'Parent';

		# make note of the default method and attribute values
		my	$default_method		  = DEFAULT_METHOD;
		my	$default_attribute	= DEFAULT_ATTRIBUTE;

		# make a copy of the accessors' code
		my	$accessors			    = ACCESSORS;

		# do we have access checking?
		my	$strict				      =  ( defined $self->check )
		  	       				                 ? $self->check : 'undef';

		# create the parent class
    #   - provided it hasn't been created before
    my  $pkg    = $self->parent;
    #   - convert the package name into a file name
    my  $file   = catfile( split '::' , $pkg ) . '.pm';
		unless ( $INC{ $file } ) {
			my	$dfn	= <<__EODfN__;
package $pkg;

use strict;
use base qw( Class::Declare::Attributes );

# add the accessors
$accessors

1;
__EODfN__

		  # attempt to instatiate this package
      __PACKAGE__->require( $dfn )
		    or die __PACKAGE__ , ": failed to create $pkg:\n\t$@";
    }

		# define the packages
		#   NB: only define base and unrelated here, the derived
		#       class simply inherits everything from base
		foreach my $pkg ( map { $self->$_() } qw( base unrelated ) ) {
			# if this package has already been defined then ignore it
      #   - convert the package name into a file name
      my  $file   = catfile( split '::' , $pkg ) . '.pm';
			next		    if ( defined $INC{ $file } );

      # does this class have a parent class?
      my  $parent = ( $pkg eq $self->base ) ? $self->parent : '';

			# create the package definition
			my	$dfn	  = <<__EODfN__;
package $pkg;

use strict;
use base qw( Class::Declare::Attributes $parent );

# define the $type attribute
#    - do we want strict access checking?
__PACKAGE__->declare( $type  => { attribute => $default_attribute } ,
                      strict => $strict                             );

# define the $type method
sub method : $type
{
	my	\$self	= shift;

	# don't have to do anything, we're only interested in whether we can call
	# this routine
	return $default_method;
} # method()

# include the accessors
$accessors

#
# We need to test attribute assignment to ensure assigned values are
# honoured. The actual assignment should happen within the defining class to
# ensure that it takes place. The comparison will be performed in the
# context class, which will trap accessor errors. This is simply a test to
# ensure lvalue and argument setting support is provided. It is overkill to
# check for all instance attributes, but it's easy enough to to so just do
# it.
#


# lvalue assignments
sub lvalue : public
{
	my	\$self	= shift;
		  \$self->attribute	= shift;
} # lvalue()


# argument assignment
sub argument : public
{
	my	\$self	= shift;
		  \$self->attribute( shift );
} # argument()


#
# Need to add a reset function for setting the attribute value back to
# it's original state (which may have been changed by the tests)
#

# reset the instance attribute
sub reset : public
{
	my	\$self	= shift;
	# NB: use argument style so that non-modifiable attributes will silently
	#     fail (other parts of the tests should pick this up)
		  \$self->attribute( shift );
} # reset()


1; # end of $pkg
__EODfN__

			# attempt to instantiate this package
      __PACKAGE__->require( $dfn )
				or warn __PACKAGE__ . ": failed to create $pkg:\n\t$@"
					and return undef;
		}

		# create the derived class
    #   - provided it hasn't been created before
        $pkg  = $self->derived;
    #   - convert the package name into a file name
        $file   = catfile( split '::' , $pkg ) . '.pm';
		unless ( $INC{ $file } ) {
		  my	$base	= $self->base;
      my	$dfn	= <<__EODfN__;
package $pkg;

use strict;
use base qw( $base );

# add the accessors
$accessors

1;
__EODfN__

		  # attempt to instatiate this package
      __PACKAGE__->require( $dfn )
        or warn __PACKAGE__ , ": failed to create $pkg:\n\t$@"
       and return undef;
    }

		# create the object instances
		$self->instance		= $self->base->new			  or return undef;
		$self->inherited	= $self->derived->new		  or return undef;
		$self->foreign		= $self->unrelated->new   or return undef;
		$self->super  		= $self->parent->new      or return undef;

		1;	# everything is OK
	} # init()

); # declare()


{ # closure for extracting the required context & target

  # define the mapping between bitmaps and names
  my  @__NAME__   = ();
      @__NAME__[ map { (   $_               ,
                         ( $_ | _INSTANCE ) )
                     } ( _CLASS , _DERIVED , _UNRELATED , _PARENT )
               ]  = qw(   base      instance derived inherited
                          unrelated foreign  parent  super        );
      
  # $name()
  #
  # Extract the name of the method specified by the given bitmap
  my  $name = sub { return $__NAME__[ $_[ 0 ] ] }; # $name()


	# $code()
	#
	# Extract the required instance/class
	my	$code	= sub {
                my  $method = $name->( $_[ 1 ] );

                return $_[ 0 ]->$method();
              };  # $code()

# context()
#
# Extract the context from the given test code.
sub context
{
	my	$self	= __PACKAGE__->private( $_[ 0 ] );

	return $code->( $self , _GET_CONTEXT->( $_[ 1 ] ) );
} # context()


# context_string()
#
# Extract a string representation for the caller enviornment.
sub context_string
{
  my  $self = __PACKAGE__->private( $_[ 0 ] );

  return $name->( _GET_CONTEXT->( $_[ 1 ] ) );
} # context_string()


# target()
#
# Extract the target from the given test code.
sub target
{
	my	$self	= __PACKAGE__->private( $_[ 0 ] );

	return $code->( $self , _GET_TARGET->( $_[ 1 ] ) );
} # target()


# target_string()
#
# Extract a string representation for the caller enviornment.
sub target_string
{
  my  $self = __PACKAGE__->private( $_[ 0 ] );

  return $name->( _GET_TARGET->( $_[ 1 ] ) );
} # target_string()

} # end of context/target closure


# focus()
#
# Extract the focus from the given test code.
sub focus
{
	my	$self	  = __PACKAGE__->private( $_[ 0 ] );
	my	$focus	= _GET_FOCUS->( $_[ 1 ] );

	return 'attribute'		if ( $focus & _ATTRIBUTE );
	return 'method';
} # focus()


# result()
#
# Extract the result from the given test code.
sub result
{
	my	$self	= __PACKAGE__->private( shift );
	return _GET_RESULT->( $_[ 0 ] );
} # result()


# test()
#
# Extract the tests from the given code.
sub test
{
	my	$self	= __PACKAGE__->private( shift );
	return _GET_TEST->( $_[ 0 ] );
} # test()


# reset()
#
# Reset the attributes of each of our object instances to the default
# values.
sub reset
{
	my	$self	= __PACKAGE__->private( shift );

	# these shouldn't fail, as we are calling publicly accessible
	# methods on class instances, but if they do, then we should raise
	# the alarm
		$_->reset( DEFAULT_ATTRIBUTE )
			foreach ( map { $self->$_() } qw( instance inherited foreign ) );

	return 1;	# everything has been reset (hopefully)
} # reset()


=item B<run(>B<)>

Run the tests.

=cut
sub run
{
	my	$self	= __PACKAGE__->public( shift );

  # generate the test message
  my  $msg  = sub { '(from ' . $self->context_string( $_[ 0 ] ) . ' on '
                             . $self->target_string(  $_[ 0 ] ) . ')'    };

	# run through each test
	TYPE: foreach my $type ( map { @{ $_ } } $self->tests ) {
		# determine the context and target
		my	$context	= $self->context( $type );
		my	$target		= $self->target( $type );

		# what tests are we to perform?
		my	$test		  = $self->test  ( $type );
		# do we want this test to live or die?
		my	$live		  = $self->result( $type );

		# now we need to determine the focus of this test
		# i.e. are we interested in an attribute or a method?
		my	$block;	# the block of code to execute
		FOCUS: foreach ( $self->focus( $type ) ) {
			# we're testing the attribute
			#    - attributes may be:
			#        . accessed
			#        . read
			#        . write by argument
			#        . write by lvalue
			/^attribute/o	&& do {
				# need to check to see if we can access the attribute
				( $test & _TEST_ACCESS )	&& do {
					if ( $live ) {
						lives_ok { $context->get( $target ) }
					         	'attribute access honoured ' . $msg->( $type );
					} else {
						 dies_ok { $context->get( $target ) }
						        'attribute access forbidden ' . $msg->( $type );
					}
				};

				# reset the attribute values
				$self->reset      unless ( $self->type eq 'abstract' );

				# need to check to see if we can access the attribute
				( $test & _TEST_READ   )	&& do {
					if ( $live ) {
						lives_and {
							is $context->get( $target ) , DEFAULT_ATTRIBUTE
						} 'attribute read honoured ' . $msg->( $type );
					} else {
						  dies_ok {
						 	   $context->get( $target )
						} 'attribute read forbidden ' . $msg->( $type );
					}
				};

				# need to check with writing to an attribute with an
				# argument
				( $test & _TEST_WRITE_ARG )	&& do {
					if ( $live ) {
						ok( $context->cmp_argument( $target )     ,
						    'attribute write argument honoured ' . $msg->( $type ) );
					} else {
						dies_ok { $context->cmp_argument( $target ) or die }
						    'attribute write argument forbidden ' . $msg->( $type );
					}
				};

				# reset the attribute values
				  $self->reset      unless ( $self->type eq 'abstract' );

				# need to check with writing to an attribute as
				# lvalue
				( $test & _TEST_WRITE_LVALUE )	&& do {
					if ( $live ) {
						ok( $context->cmp_lvalue( $target )     ,
						    'attribute write lvalue honoured ' . $msg->( $type ) );
					} else {
						dies_ok {
							$context->cmp_lvalue( $target )
						} 'attribute write lvalue forbidden ' . $msg->( $type );
					}
				};
			};

			# we're testing the method
			#    - methods may be:
			#        . accessed
			#        . read
			#    - everything else (such as lvalue assignment) is
			#        controlled by Perl, not Class::Declare::Attributes
			/^method/o		&& do {
				# do we need to check access rights?
				( $test & _TEST_ACCESS )	&& do {
					if ( $live ) {
						lives_ok { $context->call( $target ) }
						         'method access honoured ' . $msg->( $type );
					} else {
						 dies_ok { $context->call( $target ) }
						         'method access forbidden ' . $msg->( $type );
					}
				};

				# do we need to check read access rights?
				( $test & _TEST_READ )		&& do {
					if ( $live ) {
						lives_and {
							  is $context->call( $target ) , DEFAULT_METHOD
						} 'method read honoured ' . $msg->( $type );
					} else {
						  dies_ok {
						  	is $context->call( $target ) , DEFAULT_METHOD
						} 'method read forbidden '. $msg->( $type );
					}
				};
			};
		}
	}

	return 1;	# everything is OK
} # run()

=pod

=back

=head1 SEE ALSO

L<Class::Declare::Attributes>, L<Test::More>, L<Test::Exception>.

=head1 AUTHOR

Ian Brayshaw, E<lt>ibb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Ian Brayshaw. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

################################################################################
1;	# end of module
__END__
