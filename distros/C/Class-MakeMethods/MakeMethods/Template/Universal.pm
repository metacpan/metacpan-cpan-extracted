package Class::MakeMethods::Template::Universal;

use Class::MakeMethods::Template '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.00;
require Carp;

=head1 NAME

Class::MakeMethods::Template::Universal - Meta-methods for any type of object

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::Universal (
    'no_op' => [ 'twiddle' ],
    'croak' => [ 'fail', { croak_msg => 'Curses!' } ]
  );
  
  package main;

  MyObject->twiddle; 			# Does nothing
  if ( $foiled ) { MyObject->fail() }	# Dies with croak_msg

=head1 DESCRIPTION

=head1 UNIVERSAL META-METHODS

The following meta-methods and behaviors are applicable across
multiple types of classes and objects.

=head2 Universal:generic

This is not a directly-invokable method type, but instead provides code expressions for use in other method-generators.

You can use any of these features in your meta-method interfaces without explicitly importing them.

B<Modifiers>

=over 4

=item *

--private

Causes the method to croak if it is called from outside of the package which originally declared it.

Note that this protection can currently be circumvented if your class provides the method_init behavior, or another subroutine that calls methods by name.

=item *

--protected

Causes the method to croak if it is called from a package other than the declaring package and its inheritors.

Note that this protection can currently be circumvented if your class provides the method_init behavior, or another subroutine that calls methods by name.

=item *

--public

Cancels any previous -private or -protected declaration.

=item *

--self_closure

Causes the method to return a function reference which is bound to the arguments provided when it is first called.

For examples of usage, see the test scripts in t/*closure.t.

=item *

--lvalue

Adds the ":lvalue" attribute to the subroutine declaration. 

For examples of usage, see the test scripts in t/*lvalue.t.

=item *

--warn_calls

For diagnostic purposes, call warn with the object reference, method name, and arguments before executing the body of the method.


=back


B<Behaviors>

=over 4

=item *

attributes

Runtime access to method parameters.

=item *

no_op -- See below.

=item *

croak -- See below.

=item *

method_init -- See below.

=back

=cut

sub generic { 
  {
    'code_expr' => { 
      '_SELF_' => '$self',
      '_SELF_CLASS_' => '(ref _SELF_ || _SELF_)',
      '_SELF_INSTANCE_' => '(ref _SELF_ ? _SELF_ : undef)',
      '_CLASS_FROM_INSTANCE_' => '(ref _SELF_ || croak "Can\'t invoke _STATIC_ATTR_{name} as a class method")',
      '_ATTR_{}' => '$m_info->{*}',
      '_STATIC_ATTR_{}' => '_ATTR_{*}',
      '_ATTR_REQUIRED_{}' => 
	'(_ATTR_{*} or Carp::croak("No * parameter defined for _ATTR_{name}"))',
      '_ATTR_DEFAULT_{}' => 
	sub { my @a = split(' ',$_[0],2); "(_ATTR_{$a[0]} || $a[1])" },
      
      _ACCESS_PRIVATE_ => '( ( (caller)[0] eq _ATTR_{target_class} ) or croak "Attempted access to private method _ATTR_{name}")',
      _ACCESS_PROTECTED_ => '( UNIVERSAL::isa((caller)[0], _ATTR_{target_class}) or croak "Attempted access to protected method _ATTR_{name}" )',

      '_CALL_METHODS_FROM_HASH_' => q{
	  # Accept key-value attr list, or reference to unblessed hash of attrs
	  my @args = (scalar @_ == 1 and ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;
	  while ( scalar @args ) { local $_ = shift(@args); $self->$_( shift(@args) ) }
      },
      
    },
    'modifier' => {
      'self_closure' => q{ my @args = @_; return sub { unshift @_, @args; * } },
      'warn_calls' => q{ warn $self."->_STATIC_ATTR_{name}(".join(', ',@_).")\n"; * },
      'public' => q{ * },
      'private' => q{ _ACCESS_PRIVATE_; * },
      'protected' => q{ _ACCESS_PROTECTED_; * },
      '-folding' => [ 
	# Public is the default; all three options are mutually exclusive.
	'-public' => '',
	'-private -public' => '-public',
	'-protected -public' => '-public',
	'-private -protected' => '-protected',
	'-protected -private' => '-private',
      ],
      'lvalue' => { _SUB_ATTRIBS_ => ': lvalue' },
    },
    'behavior' => {
      -import => {
	'Template::Universal:no_op' => 'no_op',
	'Template::Universal:croak' => 'croak',
	'Template::Universal:method_init' => 'method_init',
      },
      attributes => sub { 
	my $m_info = $_[0]; 
	return sub {
	  my $self = shift;
	  if ( scalar @_ == 0 ) {
	    return $m_info;
	  } elsif ( scalar @_ == 1 ) {
	    return $m_info->{ shift() };
	  } else {
	    %$m_info = ( %$m_info, @_ );
	  }
	}
      },
    },
  }
}

########################################################################

=head2 no_op

For each meta-method, creates a method with an empty body.

  use Class::MakeMethods::Template::Universal (
    'no_op' => [ 'foo bar baz' ],
  );

You might want to create and use such methods to provide hooks for
subclass activity.

No interfaces or parameters supported.

=cut

sub no_op { 
   {
    'interface' => { 
      default => 'no_op',
      'no_op' => 'no_op' 
    },
    'behavior' => { 
      no_op => sub { my $m_info = $_[0]; sub { } },
    },
  }
}

########################################################################

=head2 croak

For each meta-method, creates a method which will croak if called.

  use Class::MakeMethods::Template::Universal (
    'croak' => [ 'foo bar baz' ],
  );

This is intended to support the use of abstract methods, that must
be overidden in a useful subclass.

If each subclass is expected to provide an implementation of a given method, using this abstract method will replace the generic error message below with the clearer, more explicit error message that follows it:

  Can't locate object method "foo" via package "My::Subclass"
  The "foo" method is abstract and can not be called on My::Subclass

However, note that the existence of this method will be detected by UNIVERSAL::can(), so it is not suitable for use in optional interfaces, for which you may wish to be able to detect whether the method is supported or not.

The -unsupported and -prohibited interfaces provide alternate error
messages, or a custom error message can be provided using the
'croak_msg' parameter.

=cut

sub abstract { 'croak --abstract' }

sub croak { 
   {
    'interface' => { 
      default => 'croak',
      'croak' => 'croak',
      'abstract' => { 
	'*'=>'croak', -params=> { 'croak_msg' => 
	  q/Can't locate abstract method "*" declared in "*{target_class}", called from "CALLCLASS"./ 
	}
      },
      'abstract_minimal' => { 
	'*'=>'croak', -params=> { 'croak_msg' => 
			      "The * method is abstract and can not be called" }
      },
      'unsupported' => { 
	'*'=>'croak', -params=> { 'croak_msg' => 
			      "The * method does not support this operation" }
      },
      'prohibited' => { 
	'*'=>'croak', -params=> { 'croak_msg' => 
			      "The * method is not allowed to perform this activity" }
      },
    },
    'behavior' => { 
      croak => sub { 
	  my $m_info = $_[0]; 
	  sub {
	    $m_info->{'croak_msg'} =~ s/CALLCLASS/ ref( $_[0] ) || $_[0] /ge
		if $m_info->{'croak_msg'};
	    Carp::croak( $m_info->{'croak_msg'} );
	  }
	},
    },
  }
}

########################################################################

=head2 method_init

Creates a method that accepts a hash of key-value pairs, or a
reference to hash of such pairs. For each pair, the key is interpreted
as the name of a method to call, and the value is the argument to
be passed to that method.

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Template::Universal (
    method_init => 'init',
  );
  ...
  
  my $object = MyObject->new()
  $object->init( foo => 'Foozle', bar => 'Barbados' );
  
  # Equivalent to:
  $object->foo('Foozle');
  $object->bar('Barbados');

You might want to create and use such methods to allow easy initialization of multiple object or class parameters in a single call.

B<Note>: including methods of this type will circumvent the protection of C<private> and C<protected> methods, because it an outside caller can cause an object to call specific methods on itself, bypassing the privacy protection.

=cut

sub method_init { 
  {
    'interface' => { 
      default => 'method_init',
      'method_init' => 'method_init' 
    },
    'code_expr' => { 
      '-import' => {  'Template::Universal:generic' => '*'  },
    },
    'behavior' => { 
      method_init => q{
	  _CALL_METHODS_FROM_HASH_
	  return $self;
	}
      },
  }
}

########################################################################

=head2 forward_methods

Creates a method which delegates to an object provided by another method. 

Example:

  use Class::MakeMethods::Template::Universal
    forward_methods => [ 
	 --target=> 'whistle', w, 
	[ 'x', 'y' ], { target=> 'xylophone' }, 
	{ name=>'z', target=>'zither', target_args=>[123], method_name=>do_zed },
      ];

Example: The above defines that method C<w> will be handled by the
calling C<w> on the object returned by C<whistle>, whilst methods C<x>
and C<y> will be handled by C<xylophone>, and method C<z> will be handled
by calling C<do_zed> on the object returned by calling C<zither(123)>.

B<Interfaces>:

=over 4

=item forward (default)

Calls the method on the target object. If the target object is missing, croaks at runtime with a message saying "Can't forward bar because bar is empty."

=item delegate

Calls the method on the target object, if present. If the target object is missing, returns nothing.

=back

B<Parameters>: The following additional parameters are supported:

=over 4

=item target

I<Required>. The name of the method that will provide the object that will handle the operation.

=item target_args

Optional ref to an array of arguments to be passed to the target method.

=item method_name

The name of the method to call on the handling object. Defaults to the name of the meta-method being created.

=back

=cut

sub forward_methods { 
   {
    'interface' => { 
      default => 'forward',
      'forward' => 'forward' 
    },
    'params' => { 'method_name' => '*' },
    'behavior' => {
      'forward' => sub { my $m_info = $_[0]; sub {
	my $target = $m_info->{'target'};
	my @args = $m_info->{'target_args'} ? @{$m_info->{'target_args'}} : ();
	my $obj = (shift)->$target(@args) 
	  or Carp::croak("Can't forward $m_info->{name} because $m_info->{target} is empty");
	my $method = $m_info->{'method_name'};
	$obj->$method(@_);
      }},
      'delegate' => sub { my $m_info = $_[0]; sub {
	my $target = $m_info->{'target'};
	my @args = $m_info->{'target_args'} ? @{$m_info->{'target_args'}} : ();
	my $obj = (shift)->$target(@args) 
	  or return;
	my $method = $m_info->{'method_name'};
	$obj->$method(@_);
      }},
    },
  }
}


########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Template> for information about this family of subclasses.

=cut

1;
