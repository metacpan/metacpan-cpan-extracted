package Class::MakeMethods::Emulator::MethodMaker;

use Class::MakeMethods '-isasubclass';
require Class::MakeMethods::Emulator;

$VERSION = 1.03;

use strict;

=head1 NAME

Class::MakeMethods::Emulator::MethodMaker - Emulate Class::MethodMaker 


=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Emulator::MethodMaker( 
    new_with_init => 'new',
    get_set       => [ qw / foo bar baz / ];
  );

  ... OR ...

  package MyObject;
  use Class::MakeMethods::Emulator::MethodMaker '-take_namespace';
  use Class::MethodMaker ( 
    new_with_init => 'new',
    get_set       => [ qw / foo bar baz / ];
  );


=head1 DESCRIPTION

This module provides emulation of Class::MethodMaker, using the Class::MakeMethods framework.

Although originally based on Class::MethodMaker, the calling convention
for Class::MakeMethods differs in a variety of ways; most notably, the names
given to various types of methods have been changed, and the format for
specifying method attributes has been standardized. This package uses
the aliasing capability provided by Class::MakeMethods, defining methods
that modify the declaration arguments as necessary and pass them off to
various subclasses of Class::MakeMethods.


=head1 COMPATIBILITY

Full compatibility is maintained with version 1.03; some of the
changes in versions 1.04 through 1.10 are not yet included.

The test suite from Class::MethodMaker version 1.10 is included
with this package, in the t/emulator_class_methodmaker/ directory. 
The unsupported tests have names ending in ".todo".

The tests are unchanged from those in the Class::MethodMaker
distribution, except for the substitution of
C<Class::MakeMethods::Emulator::MethodMaker> in the place of
C<Class::MethodMaker>.

In cases where earlier distributions of Class::MethodMaker contained
a different version of a test, it is also included. (Note that
version 0.92's get_concat returned '' for empty values, but in
version 0.96 this was changed to undef; this emulator follows the
later behavior. To avoid "use of undefined value" warnings from
the 0.92 version of get_concat.t, that test has been modified by
appending a new flag after the name, C<'get_concat --noundef'>,
which restores the earlier behavior.)


=head1 USAGE

There are several ways to call this emulation module:

=over 4

=item *

Direct Access

Replace occurances in your code of C<Class::MethodMaker> with C<Class::MakeMethods::Emulator::MethodMaker>.

=item *

Install Emulation

If you C<use Class::MakeMethods::Emulator::MethodMaker '-take_namespace'>, the Class::MethodMaker namespace will be aliased to this package, and calls to the original package will be transparently handled by this emulator.

To remove the emulation aliasing, call C<use Class::MakeMethods::Emulator::MethodMaker '-release_namespace'>.

B<Note:> This affects B<all> subsequent uses of Class::MethodMaker in your program, including those in other modules, and might cause unexpected effects.

=item *

The -sugar Option

Passing '-sugar' as the first argument in a use or import call will cause the 'methods' package to be declared as an alias to this one.

This allows you to write declarations in the following manner.

  use Class::MakeMethods::Emulator::MethodMaker '-sugar';

  make methods
    get_set => [ qw / foo bar baz / ],
    list    => [ qw / a b c / ];

B<Note:> This feature is deprecated in Class::MethodMaker version 0.96 and later. 

=back

=cut

my $emulation_target = 'Class::MethodMaker';

sub import {
  my $mm_class = shift;
  
  if ( scalar @_ and $_[0] =~ /^-take_namespace/ and shift ) {
    Class::MakeMethods::Emulator::namespace_capture(__PACKAGE__, $emulation_target);
  } elsif ( scalar @_ and $_[0] =~ /^-release_namespace/ and shift ) {
    Class::MakeMethods::Emulator::namespace_release(__PACKAGE__, $emulation_target);
  }
  
  if ( scalar @_ and $_[0] eq '-sugar' and shift ) {
    Class::MakeMethods::Emulator::namespace_capture(__PACKAGE__, "methods");
  }
  
  $mm_class->make( @_ ) if ( scalar @_ );
}


=head1 METHOD CATALOG

B<NOTE:> The documentation below is derived from version 1.02 of
Class::MethodMaker. Class::MakeMethods::Emulator::MethodMaker
provides support for all of the features and examples shown below,
with no changes required.


=head1 CONSTRUCTOR METHODS

=head2 new

Equivalent to Class::MakeMethods 'Template::Hash:new --with_values'.

=cut

sub new 	  { return 'Template::Hash:new --with_values' }


=head2 new_with_init

Equivalent to Class::MakeMethods 'Template::Hash:new --with_init'.

=cut

sub new_with_init { return 'Template::Hash:new --with_init' }


=head2 new_hash_init

Equivalent to Class::MakeMethods 'Template::Hash:new --instance_with_methods'.

=cut

sub new_hash_init { return 'Template::Hash:new --instance_with_methods' }


=head2 new_with_args

Equivalent to Class::MakeMethods 'Template::Hash:new --with_values'.

=cut

sub new_with_args { return 'Template::Hash:new --with_values' }


=head2 copy

Equivalent to Class::MakeMethods 'Template::Hash:new --copy_with_values'.

=cut

sub copy 	  { return 'Template::Hash:new --copy_with_values' }


=head1 SCALAR ACCESSORS

=head2 get_set

Basically equivalent to Class::MakeMethods 'Template::Hash:scalar', except that various arguments are intercepted and converted into the parallel Class::MakeMethods::Template interface declarations.

=cut

my $scalar_interface = { '*'=>'get_set', 'clear_*'=>'clear' };

sub get_set 	  { 
  shift and return [ 
    ( ( $_[0] and $_[0] eq '-static' and shift ) ? 'Template::Static:scalar' 
						 : 'Template::Hash:scalar' ), 
    '-interface' => $scalar_interface, 
    map { 
      ( ref($_) eq 'ARRAY' ) 
	? ( '-interface'=>{ 
	  ( $_->[0] ? ( $_->[0] => 'get_set' ) : () ),
	  ( $_->[1] ? ( $_->[1] => 'clear' ) : () ),
	  ( $_->[2] ? ( $_->[2] => 'get' ) : () ),
	  ( $_->[3] ? ( $_->[3] => 'set_return' ) : () ),
	} ) 
	: ($_ eq '-compatibility') 
	    ? ( '-interface', $scalar_interface ) 
	    : ($_ eq '-noclear') 
		? ( '-interface', 'default' ) 
		: ( /^-/ ? "-$_" : $_ ) 
    } @_ 
  ]
}


=head2 get_concat

Equivalent to Class::MakeMethods 'Template::Hash:string' with a special interface declaration that provides the get_concat and clear behaviors.

=cut

my $get_concat_interface = { 
  '*'=>'get_concat', 'clear_*'=>'clear', 
  '-params'=>{ 'join' => '', 'return_value_undefined' => undef() } 
};

my $old_get_concat_interface = { 
  '*'=>'get_concat', 'clear_*'=>'clear', 
  '-params'=>{ 'join' => '', 'return_value_undefined' => '' } 
};

sub get_concat 	  { 
  shift and return [ 'Template::Hash:string', '-interface', 
	( $_[0] eq '--noundef' ? ( shift and $old_get_concat_interface ) 
			       : $get_concat_interface ), @_ ]
}

=head2  counter

Equivalent to Class::MakeMethods 'Template::Hash:number --counter'.

=cut

sub counter 	  { return 'Template::Hash:number --counter' }


=head1 OBJECT ACCESSORS

Basically equivalent to Class::MakeMethods 'Template::Hash:object' with an declaration that provides the "delete_x" interface. Due to a difference in expected argument syntax, the incoming arguments are revised before being delegated to Template::Hash:object.

=cut

my $object_interface = { '*'=>'get_set_init', 'delete_*'=>'clear' };

sub object 	  { 
  shift and return [ 
    'Template::Hash:object', 
    '-interface' => $object_interface, 
    _object_args(@_) 
  ] 
}

sub _object_args {
  my @meta_methods;
  ! (@_ % 2) or Carp::croak("Odd number of arguments for object declaration");
  while ( scalar @_ ) {
    my ($class, $list) = (shift(), shift());
    push @meta_methods, map {
      (! ref $_) ? { name=> $_, class=>$class } 	
 	 	 : { name=> $_->{'slot'}, class=>$class, 
		    delegate=>( $_->{'forward'} || $_->{'comp_mthds'} ) }
    } ( ( ref($list) eq 'ARRAY' ) ? @$list : ($list) );
  }
  return @meta_methods;
}


=head2 object_list

Basically equivalent to Class::MakeMethods 'Template::Hash:object_list' with an declaration that provides the relevant helper methods. Due to a difference in expected argument syntax, the incoming arguments are revised before being delegated to Template::Hash:object_list.

=cut

my $array_interface = { 
  '*'=>'get_push', 
  '*_set'=>'set_items', 'set_*'=>'set_items', 
  map( ('*_'.$_ => $_, $_.'_*' => $_ ), 
	qw( pop push unshift shift splice clear count ref index )),
};

sub object_list { 
  shift and return [ 
    'Template::Hash:array_of_objects', 
    '-interface' => $array_interface, 
    _object_args(@_) 
  ];
}

=head2 forward

Basically equivalent to Class::MakeMethods 'Template::Universal:forward_methods'. Due to a difference in expected argument syntax, the incoming arguments are revised before being delegated to Template::Universal:forward_methods.

  forward => [ comp => 'method1', comp2 => 'method2' ]

Define pass-through methods for certain fields.  The above defines that
method C<method1> will be handled by component C<comp>, whilst method
C<method2> will be handled by component C<comp2>.

=cut

sub forward {
  my $class = shift;
  my @results;
  while ( scalar @_ ) { 
    my ($comp, $method) = ( shift, shift );
    push @results, { name=> $method, target=> $comp };
  }
  [ 'forward_methods', @results ]
}



=head1 REFERENCE ACCESSORS

=head2 list

Equivalent to Class::MakeMethods 'Template::Hash:array' with a custom method naming interface.

=cut

sub list { 
  shift and return [ 'Template::Hash:array', '-interface' => $array_interface, @_ ];
}


=head2 hash

Equivalent to Class::MakeMethods 'Template::Hash:hash' with a custom method naming interface.

=cut

my $hash_interface = { 
  '*'=>'get_push', 
  '*s'=>'get_push', 
  'add_*'=>'get_set_items', 
  'add_*s'=>'get_set_items', 
  'clear_*'=>'delete', 
  'clear_*s'=>'delete', 
  map {'*_'.$_ => $_} qw(push set keys values exists delete tally clear),
};

sub hash { 
  shift and return [ 'Template::Hash:hash', '-interface' => $hash_interface, @_ ];
}


=head2 tie_hash

Equivalent to Class::MakeMethods 'Template::Hash:tiedhash' with a custom method naming interface.

=cut

sub tie_hash { 
  shift and return [ 'Template::Hash:tiedhash', '-interface' => $hash_interface, @_ ];
}

=head2 hash_of_lists

Equivalent to Class::MakeMethods 'Template::Hash:hash_of_arrays', or if the -static flag is present, to 'Template::Static:hash_of_arrays'.

=cut

sub hash_of_lists { 
  shift and return ( $_[0] and $_[0] eq '-static' and shift ) 
	? [ 'Template::Static:hash_of_arrays', @_ ]
	: [ 'Template::Hash:hash_of_arrays', @_ ]
}


=head1 STATIC ACCESSORS

=head2 static_get_set

Equivalent to Class::MakeMethods 'Template::Static:scalar' with a custom method naming interface.

=cut

sub static_get_set { 
  shift and return [ 'Template::Static:scalar', '-interface', $scalar_interface, @_ ] 
}

=head2 static_list

Equivalent to Class::MakeMethods 'Template::Static:array' with a custom method naming interface.

=cut

sub static_list { 
  shift and return [ 'Template::Static:array', '-interface' => $array_interface, @_ ];
}

=head2 static_hash

Equivalent to Class::MakeMethods 'Template::Static:hash' with a custom method naming interface.

=cut

sub static_hash { 
  shift and return [ 'Template::Static:hash', '-interface' => $hash_interface, @_ ];
}


=head1 GROUPED ACCESSORS

=head2 boolean

Equivalent to Class::MakeMethods 'Template::Static:bits' with a custom method naming interface.

=cut

my $bits_interface = { 
  '*'=>'get_set', 'set_*'=>'set_true', 'clear_*'=>'set_false',
  'bit_fields'=>'bit_names', 'bits'=>'bit_string', 'bit_dump'=>'bit_hash' 
};

sub boolean 	  { 
  shift and return [ 'Template::Hash:bits', '-interface' => $bits_interface, @_ ];
}


=head2 grouped_fields

Creates get/set methods like get_set but also defines a method which
returns a list of the slots in the group.

  use Class::MakeMethods::Emulator::MethodMaker
    grouped_fields => [
      some_group => [ qw / field1 field2 field3 / ],
    ];

Its argument list is parsed as a hash of group-name => field-list
pairs. Get-set methods are defined for all the fields and a method with
the name of the group is defined which returns the list of fields in the
group.

=cut

sub grouped_fields {
  my ($class, %args) = @_;
  my @methods;
  foreach (keys %args) {
    my @slots = @{ $args{$_} };
    push @methods, 
	$_, sub { @slots },
	$class->make( 'get_set', \@slots );
  }
  return @methods;
}

=head2 struct

Equivalent to Class::MakeMethods 'Template::Hash::struct'.

B<Note:> This feature is included but not documented in Class::MethodMaker version 1. 


=cut

sub struct	  { return 'Template::Hash:struct' }


=head1 INDEXED ACCESSORS

=head2 listed_attrib

Equivalent to Class::MakeMethods 'Template::Flyweight:boolean_index' with a custom method naming interface.

=cut

sub listed_attrib   { 
  shift and return [ 'Template::Flyweight:boolean_index', '-interface' => { 
	  '*'=>'get_set', 'set_*'=>'set_true', 'clear_*'=>'set_false',
	  '*_objects'=>'find_true', }, @_ ]
}


=head2 key_attrib

Equivalent to Class::MakeMethods 'Template::Hash:string_index'.

=cut

sub key_attrib      { return 'Template::Hash:string_index' }

=head2 key_with_create

Equivalent to Class::MakeMethods 'Template::Hash:string_index --find_or_new'.

=cut

sub key_with_create { return 'Template::Hash:string_index --find_or_new'}


=head1 CODE ACCESSORS

=head2 code

Equivalent to Class::MakeMethods 'Template::Hash:code'.

=cut

sub code 	  { return 'Template::Hash:code' }


=head2 method

Equivalent to Class::MakeMethods 'Template::Hash:code --method'.

=cut

sub method 	  { return 'Template::Hash:code --method' }


=head2 abstract

Equivalent to Class::MakeMethods 'Template::Universal:croak --abstract'.

=cut

sub abstract { return 'Template::Universal:croak --abstract' }


=head1 ARRAY CONSTRUCTOR AND ACCESSORS

=head2 builtin_class (EXPERIMENTAL)

Equivalent to Class::MakeMethods 'Template::StructBuiltin:builtin_isa' with a modified argument order.

=cut

sub builtin_class { 
  shift and return [ 'Template::StructBuiltin:builtin_isa', 
			'-new_function'=>(shift), @{(shift)} ]
}

=head1 CONVERSION

If you wish to convert your code from use of the Class::MethodMaker emulator to direct use of Class::MakeMethods, you will need to adjust the arguments specified in your C<use> or C<make> calls.

Often this is simply a matter of replacing the names of aliased method-types listed below with the new equivalents.

For example, suppose that you code contained the following declaration:

  use Class::MethodMaker ( 
    counter => [ 'foo' ]
  );

Consulting the listings below you can find that C<counter> is an alias for C<Hash:number --counter> and you could thus revise your declaration to read:

  use Class::MakeMethods ( 
    'Hash:number --counter' => [ 'foo' ] 
  );

However, note that those methods marked "(with custom interface)" below have a different default naming convention for helper methods in Class::MakeMethods, and you will need to either supply a similar interface or alter your module's calling interface. 

Also note that the C<forward>, C<object>, and C<object_list> method types, marked "(with modified arguments)" below, require their arguments to be specified differently. 

See L<Class::MakeMethods::Template::Generic> for more information about the default interfaces of these method types.


=head2 Hash methods

The following equivalencies are declared for old meta-method names that are now handled by the Hash implementation:

  new 		   'Template::Hash:new --with_values'
  new_with_init    'Template::Hash:new --with_init'
  new_hash_init    'Template::Hash:new --instance_with_methods'
  copy	 	   'Template::Hash:copy'
  get_set 	   'Template::Hash:scalar' (with custom interfaces)
  counter 	   'Template::Hash:number --counter'
  get_concat 	   'Template::Hash:string --get_concat' (with custom interface)
  boolean 	   'Template::Hash:bits' (with custom interface)
  list 		   'Template::Hash:array' (with custom interface)
  struct           'Template::Hash:struct'
  hash	 	   'Template::Hash:hash' (with custom interface)
  tie_hash 	   'Template::Hash:tiedhash' (with custom interface)
  hash_of_lists    'Template::Hash:hash_of_arrays'
  code 		   'Template::Hash:code'
  method 	   'Template::Hash:code --method'
  object 	   'Template::Hash:object' (with custom interface and modified arguments)
  object_list 	   'Template::Hash:array_of_objects' (with custom interface and modified arguments)
  key_attrib       'Template::Hash:string_index'
  key_with_create  'Template::Hash:string_index --find_or_new'

=head2 Static methods

The following equivalencies are declared for old meta-method names
that are now handled by the Static implementation:

  static_get_set   'Template::Static:scalar' (with custom interface)
  static_hash      'Template::Static:hash' (with custom interface)

=head2 Flyweight method

The following equivalency is declared for the one old meta-method name
that us now handled by the Flyweight implementation:

  listed_attrib   'Template::Flyweight:boolean_index'

=head2 Struct methods

The following equivalencies are declared for old meta-method names
that are now handled by the Struct implementation:

  builtin_class   'Template::Struct:builtin_isa'

=head2 Universal methods

The following equivalencies are declared for old meta-method names
that are now handled by the Universal implementation:

  abstract         'Template::Universal:croak --abstract'
  forward          'Template::Universal:forward_methods' (with modified arguments)


=head1 EXTENDING

In order to enable third-party subclasses of MethodMaker to run under this emulator, several aliases or stub replacements are provided for internal Class::MethodMaker methods which have been eliminated or renamed.

=over 4

=item *

install_methods - now simply return the desired methods

=item *

find_target_class - now passed in as the target_class attribute

=item *

ima_method_maker - no longer supported; use target_class instead

=back

=cut

sub find_target_class { (shift)->_context('TargetClass') }
sub get_target_class { (shift)->_context('TargetClass') }
sub install_methods { (shift)->_install_methods(@_) }
sub ima_method_maker { 1 }


=head1 BUGS

This module aims to provide a 100% compatible drop-in replacement for Class::MethodMaker; if you detect a difference when using this emulation, please inform the author. 


=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Emulator> for more about this family of subclasses.

See L<Class::MethodMaker> for more information about the original module.

A good introduction to Class::MethodMaker is provided by pages 222-234 of I<Object Oriented Perl>, by Damian Conway (Manning, 1999).

  http://www.browsebooks.com/Conway/ 

=cut

1;
