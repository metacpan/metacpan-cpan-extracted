# (X)Emacs mode: -*- cperl -*-

# $Author: domi $
# $Date: 2004/12/13 12:19:43 $
# $Name:  $
# $Revision: 1.5 $

package Class::IntrospectionMethods;

=head1 NAME

Class::IntrospectionMethods - creates methods with introspection

=head1 SYNOPSIS

  use Class::IntrospectionMethods qw/make_methods/;

  make_methods 
    (
      parent,
      global_catalog => 
        {
           name => 'metacat',
           list => 
             [
		[qw/foo/]     => f_cat,
		[qw/bar baz/] => b_cat,
       	     ],
        }
      new_with_init => 'new',
      get_set       => [ qw /foo bar baz / ];
    ) ;

=head1 DESCRIPTION

This module provides:

=over

=item *

A way to set up a lot of get/set method. These get/set methods can
access plain scalars, array, hash. These scalar, hash or array can be
tied (See L<perltie>) with classes specified by the user. The element
of these arrays or hashes can be constrained to be object, tied
scalar.

=item *

A way to later query the object or class to retrieve the list of
methods (aka slots) created by this module.

=item *

A way to organize these slots in several catalogs.

=item *

When a slot contains object or tied scalars hashes or arrays, the
contained object can be queried for the container object.
In other words, the parent object (the one constructed by
C<Class::IntrospectionMethods> contains a child object in one of its
slots either as a plain object or an object hidden behind a tied
construct. C<Class::IntrospectionMethods> will provide the child
object a method to retrieve the parent object reference.

=back

For instance, you can use this module to create a tree where each node
or leaf is an object. In this case, this module provides methods to
navigate up the tree of objects with the installed "parent" method.

In other words, this module provides special methods to enable the
user to navigate up or down a tree (or directed graph) using
introspection (to go down) and the "parent" method to go up.

You may notice similarities between this module and
L<Class::MethodMaker>. In fact this module was written from
Class::MethodMaker v1.08, but it does not provide most of the fancy
methods of Class::MethodMaker. Only scalar, array and hash
accessors (with their tied and objects variants) are provided.

Originally, the introspection and "parent" functionalities were
implemented in Class::MethodMaker. Unfortunately, they were not
accepted by Class::MethodMaker's author since they did not fit his
own vision of his module (fair enough).

The old API of L<Class::MethodMaker> is provided as deprecated
methods. Using the new (and hopefully more consistent) API is
prefered.

=cut

# --------------------------------------------------------------

use strict;
use warnings ;

# Inheritance -------------------------

#use AutoLoader;
#use vars qw( @ISA );
#@ISA = qw ( AutoLoader );

use vars qw( $VERSION @ISA @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(make_methods set_obsolete_behavior set_parent_method_name);

# Utility -----------------------------

# Necessary for parent feature
use Scalar::Util qw(isweak weaken) ;
use Class::IntrospectionMethods::Catalog 
  qw/set_global_catalog set_method_info set_method_in_catalog/;
use Class::IntrospectionMethods::Parent 
  qw/set_parent_method_name graft_parent_method/ ;

use Carp qw( carp cluck croak );

my $obsolete_behavior = 'carp' ;
my $support_legacy = 0 ;
my $legacy_object_init = 'cmm_init' ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

=head1 Transition from Class::MethodMaker

This module was forked from Class::MethodMaker v1.08. To ease
migration from older project (which include a proprietary project of
mine) using Class::MethodMaker to Class::IntrospectionMethods, a
compatiblity mode is provided. (although some features of
L<Class::MethodMaker> will not work. See
L<Class::IntrospectionMethods::Legacy> for details)

You can use the following function to finely tune the compatibility
behavior to either croak, carp (See L<Carp> for details) or be silent.

One note: I provide backward compatibility for Class::MethodMaker
v1.08 and the modification I made that were later refused. So you may
notice compatibility features that do not exist in Class::MethodMaker
v1.08.

=head2 set_obsolete_behavior ( behavior, provide_legacy_method)

C<behavior> is either C<skip>, C<carp> or C<croak>. (default is
C<carp>).

C<provide_legacy_method> is either 1 or 0. Default 0. When set to one,
this module will provide methods that were only available in the
modified version of Class::MethodMaker v1.08.

=cut

sub set_obsolete_behavior
  {
    ($obsolete_behavior, $support_legacy) = @_ ;
    Class::IntrospectionMethods::Parent::set_obsolete_behavior (@_) ;
    Class::IntrospectionMethods::Catalog::set_obsolete_behavior (@_) ;
  }

# internal
sub warn_obsolete
  {
    return if $obsolete_behavior eq 'skip' ;
    no strict 'refs' ;
    $obsolete_behavior->(@_) ;
  }

sub ima_method_maker { 1 };

sub find_target_class {
  # Find the class to add the methods to. I'm assuming that it would
  # be the first class in the caller() stack that's not a subsclass of
  # IntrospectionMethods. If for some reason a sub-class of
  # IntrospectionMethods also wanted to use IntrospectionMethods it
  # could redefine ima_method_maker to return a false value and then
  # $class would be set to it.
  my $class;
  my $i = 0;
  while (1) 
    {
      $class = (caller($i++))[0];
      last unless ( $class->isa('Class::IntrospectionMethods')
		    and
		    &{$class->can ('ima_method_maker')} );
    }
  return $class;
}

# -------------------------------------

my %legacy_catalog ;

my %default_user_options = 
  (
   catalog_name => undef,

   # When set, any object stored in a slot (either plain, hashed or
   # arrayed slot) will get a method to fetch the parent object.
   provide_parent_method => 0 ,

   #  method called after object creation to perform special
   #  initialisation. This specifies the default name
   object_init_method => 'cim_init' ,

   #whether to autovivify object stored in slots
   auto_vivify => 1
  ) ;

my $child_init = sub
  {
    my ($obj,$init_method) = @_ ;

    return unless defined $obj ;

    if (defined $init_method && $obj->can($init_method))
      {
	$obj->$init_method()  ;
      }
    elsif ($support_legacy && $obj->can($legacy_object_init)) 
      {
	warn_obsolete("calling obsolete $legacy_object_init on ".ref($obj)) ;
	$obj->$legacy_object_init() ;
      }
  } ;

# set legacy catalog methods that were defined in modified version of
# Class::MethodMaker v1.08
sub set_legacy_methods
  {
    my $target_class = shift ;

    return
      (
       CMM_CATALOG_LIST => 
       sub {my $p = ref $_[0] ? shift : $target_class; 
	    $p->CMM_CATALOG_LEGACY()->all_catalog} ,

       CMM_CATALOG      => 
       sub {
	 my $p = ref($_[0]) ? shift : $target_class; 
	 my @catalog_names = scalar @_ ? @_ :
	   $p->CMM_CATALOG_LEGACY()->all_catalog ;
	 my @result = $p->CMM_CATALOG_LEGACY()->slot(@catalog_names);
	 return wantarray ? @result : \@result ;
       },

       CMM_SLOT_CATALOG => sub 
       {
	 my $p = ref $_[0] ? shift : $target_class;
	 my $slot = shift ;
	 $p->CMM_CATALOG_LEGACY()->change($slot, shift) if @_ ;
	 my @r = $p->CMM_CATALOG_LEGACY()->catalog($slot);
	 return $r[0] ; # legacy method can only return 1 item
       } ,

       CMM_SLOT_DETAIL  => 
       sub {my $p = ref $_[0] ? shift : $target_class; 
	    my $res = $p->CMM_CATALOG_LEGACY()->info(shift);
	    return wantarray ? @$res : $res ;
	  }
      ) ;
  }

sub make_methods 
  {
    my (@args) = @_;

    my $target_class = find_target_class;

    my @legacy_catalog_methods = set_legacy_methods($target_class) ;

    # user option used through this call to make_methods. The copy is
    # done to provide a closure.
    my %user_options = %default_user_options ;

    # Each meta-method is responsible for calling install_methods() to
    # get it's methods installed.
    while (1) 
      {
	my $meta_method = shift @args or last;

	if ($meta_method =~ /^-?parent$/ ) 
	  {
	    $user_options{provide_parent_method} = 1 ;
	  }
	elsif ($meta_method =~ /^-?noparent$/ )
	  {
	    $user_options{provide_parent_method} = 0 ;
	  }
	elsif ($meta_method =~ /^-?catalog$/) 
	  {
	    # legacy mode
	    if ($support_legacy && not defined $legacy_catalog{$target_class})
	      {
		warn_obsolete("-catalog is deprecated");
		my @legacy = ( name => 'CMM_CATALOG_LEGACY',
			       list => [] ) ;
		my %meth = (set_global_catalog($target_class, @legacy), 
			    @legacy_catalog_methods) ;
		install_methods (%meth) ;
		$legacy_catalog{$target_class} = 1;
	      }
	    $user_options{catalog_name} = shift @args ;
	  }
	elsif ($meta_method =~ /^-?nocatalog$/)
	  {
	    $user_options{catalog_name} = undef ;
	  }
	elsif ($meta_method =~ /^-?global[_-]catalog$/i)
	  {
	    my $struct = shift @args;
	    my (%meth) = set_global_catalog($target_class, %$struct) ;
	    install_methods (%meth) ;
	    $legacy_catalog{$target_class} = 1;
	  }
	else
	  {
	    my $arg = shift @args or
	      croak "make_methods: No arg for $meta_method";
	    my @args = ref($arg) eq 'ARRAY' ? @$arg : ($arg);
	    no strict 'refs' ;
	    #print "Calling $meta_method\n";
	    $meta_method->(\%user_options,@args);
	  }
      }
  }

sub store_slot_in_catalog
  {
    my $slot = shift ;
    my $catalog_name = shift ;

    my $target_class = find_target_class;

    my @details = @_ ;
    set_method_info($target_class, $slot, \@details) ;

    return unless defined $catalog_name ;

    set_method_in_catalog($target_class, $slot, $catalog_name) ;
  }

sub install_methods
  {
    my (%methods) = @_;

    no strict 'refs';

    my $target_class = find_target_class;
    my $package = $target_class . "::";

    my ($name, $code);
    while (($name, $code) = each %methods) 
      {
	# add the method unless it's already defined (which should only
	# happen in the case of static methods, I think.)
	my $reftype = ref $code;
	if ( $reftype eq 'CODE' ) 
	  {
	    *{"$package$name"} = $code unless defined *{"$package$name"}{CODE};
	  }
	else 
	  {
	    croak "What do you expect me to do with this?: $code\n";
	  }
      }
  }

=head1 CLASS INTROSPECTION

Class::IntrospectionMethods provides a set of features that enable you
to query the available methods of a class. These methods can be
invoked as class methods or object methods. From now on, a class
created with Class::IntrospectionMethods will be called a CIMed class.

The top-down introspection is triggered by the C<global_catalog>
option.

=head2 slot query: the global_catalog option

When set, the C<global_catalog> will invoke the
L<Class::IntrospectionMethods::Catalog/set_global_catalog>
function. This function will use the parameters you passed to the
C<global_catalog> option to install a new method in your class. E.g.,
this C<global_catalog> option:

 package Foo::Bar ;
 use Class::IntrospectionMethods qw/make_methods/;

 make_methods
  (
    global_catalog => 
     {
      name => 'metacat',
      list => [
               [qw/foo bar baz/]                 => foo_cat,
               [qw/a b z/]                       => alpha_cat,
              ],
     },
  )

will enable you to call:

  &Foo::Bar::metacat->all_catalog ; # return alpha_cat foo_cat
  my $obj = Foo::Bar-> new;
  $obj -> metacat->all_catalog ; # also return alpha_cat foo_cat

See L<Class::IntrospectionMethods::Catalog> for:

=over

=item *

The other informations you can retrieve through the global catalog.

=item *

How to move a slot from one catalog to another at run-time (only the
object catalog can be modified)

=item *

The distinction between the class catalog and the object catalog

=back

Note that IntrospectionMethods does not check whether the method
declared in global_catalog are actually created by
IntrospectionMethods or created elsewhere.


=head2 From slot to object: the parent option.

If you use tied scalars (with the C<tie_scalar> or C<hash> method
types), or object method type, your tied scalars or objects may need
to call the parent CIMed object.

For instance, if you want to implement error handling in your tied
scalar or objects that will call the parent CIMed object or display
error messages giving back to the user the slot name containing the
faulty object.

So if you need to query the slot name, or index value (for C<hash> or
C<array> method types), or be able to call the parent object, you can
use the C<parent> option when creating the parent CIMed class:

 package FOO ;
 use Class::IntrospectionMethods
   'parent' ,
   object => [ foo => 'My::Class' ];

Using this option will graft I<one> attribute and its accessor
method. Be default, this attribute and accessor method will be named
C<cim_parent>, but this can be changed with C<set_parent_method_name>.

This attribute contains (and the accessor method will return) a
C<Class::IntrospectionMethods::ParentInfo> object. This object
features methods C<index_value>, C<slot_name> and C<parent>.
See L<Class::IntrospectionMethods::Parent/"ParentInfo class"> for
more details.

=over

=item C<CMM_PARENT> 

Reference of the parent object.

=item C<CMM_SLOT_NAME>

slot name to use to get the child object from the parent.

=item C<CMM_INDEX_VALUE>

index value (for C<tie_tie_hash> method type) to use to get the child
object from the parent.

=back

When using the C<-parent> option, a C<CMM_PARENT>, C<CMM_SLOT_NAME>
and C<CMM_INDEX_VALUE> methods are also grafted to the child's
class.

Here is an example to retrieve a parent object :

 package FOO ;
 use ExtUtils::testlib;
  '-parent' ,
  object_tie_hash =>
  [
   {
    slot => 'bar',
    tie_hash => ['MyHash'],
    class => ['MyObj', 'a' => 'foo']
   }
  ],
  new => 'new';

 package main;

 my $o = new X;

 my $obj = $o->a('foo') ;
 my $p= $obj->metadad->parent; # $p is $o

See L<Class::IntrospectionMethods::Parent/EXAMPLE> for further
details

=head1 SUPPORTED METHOD TYPES

=head2 new

Creates a basic constructor.

Takes a single string or a reference to an array of strings as its
argument.  For each string creates a simple method that creates and
returns an object of the appropriate class.

This method may be called as a class method, as usual, or as in instance
method, in which case a new object of the same class as the instance
will be created.

=cut

sub new 
  {
    my ($user_options, @args) = @_;
    my %methods;
    foreach (@args) 
      {
	$methods{$_} = sub 
	  {
	    my $class = shift;
	    $class = ref $class || $class;
	    bless {}, $class;
	  };
      }
    install_methods(%methods);
  }

=head2 new_with_init

Creates a basic constructor which calls a method named C<init> after
instantiating the object. The C<init> method should be defined in the
class using IntrospectionMethods.

Takes a single string or a reference to an array of strings as its
argument.  For each string creates a simple method that creates an
object of the appropriate class, calls C<init> on that object
propagating all arguments, before returning the object.

This method may be called as a class method, as usual, or as in instance
method, in which case a new object of the same class as the instance
will be created.

=cut

sub new_with_init {
  my ($user_options, @args) = @_;
  my %methods;
  foreach (@args) {
    my $field = $_;
    $methods{$field} = sub {
      my $class = shift;
      $class = ref $class || $class;
      my $self = {};
      bless $self, $class;
      $self->init (@_);
      return $self;
    };
  }
  install_methods(%methods);
}

# ----------------------------------------------------------------------------

=head2 new_with_args

Creates a basic constructor.

Takes a single string or a reference to an array of strings as its
argument.  For each string creates a simple method that creates and
returns an object of the appropriate class.

This method may be called as a class method, as usual, or as in instance
method, in which case a new object of the same class as the instance
will be created.

Constructor arguments will be stored as a key, value pairs in the
object. No check is done regarding the consistencies of the data
passed to the constructor and the accessor methods created.

=cut

sub new_with_args 
  {
    my ($user_options, @args) = @_;
    my %methods;
    foreach (@args) 
      {
	$methods{$_} = sub 
	  {
	    my $class = shift;
	    my @c_args = @_ ;
	    $class = ref $class || $class;
	    my $self = { @c_args };
	    bless $self, $class;
	  };
      }
    install_methods(%methods);
  }

=head2 get_set

Takes a single string or a reference to an array of strings as its
argument.  Each string specifies a slot, for which accessor methods are
created. E.g.

  get_set => 'foo',
  get_set => [qw/foo bar/],

The accessor methods are, by default:

=over 4

=item   x

If an argument is provided, sets a new value for x.  This is true even
if the argument is undef (cf. no argument, which does not set.)

Returns (new) value.

Value defaults to undef.

=item   clear_x

Sets value to undef.  This is exactly equivalent to

  $foo->x (undef)

No return.

=back

This is your basic get/set method, and can be used for slots
containing any scalar value, including references to non-scalar
data. Note, however, that IntrospectionMethods has meta-methods that
define more useful sets of methods for slots containing references to
lists, hashes, and objects.

=cut

sub get_set 
  {
    my ($user_options, @args) = @_;
    my @methods;

    foreach my $arg (@args) 
      {
	my $slot = $arg ;

	store_slot_in_catalog
	  ($arg, $user_options->{catalog_name}, slot_type => 'scalar') ;

	push @methods, $arg => 
	  sub 
	    {
	      my $self = shift;
	      if ( @_ ) {$self->{$slot} = shift;} 
	      else {$self->{$slot};}
	    };
      }

    install_methods (@methods);
  }

=head2 object

Creates methods for accessing a slot that contains an object of a given
class.

   object => [
              phooey => { class => 'Foo' },
               [ qw / bar1 bar2 bar3 / ] => { class => 'Bar'},
              foo => { class => 'Baz'
                       constructor_args => [ set => 'it' ]},
              [qw/dog fox/] => { class => 'Fob',
                       constructor_args => [ sound => 'bark' ] },
              cat => { class => 'Fob',
                       constructor_args => [ sound => 'miaow' ]}

              tiger => { class => 'Special',
                         init => 'my_init' # method to call after creation 
                       }
             ]

The main argument is an array reference. The array should contain a
set of C<< slot_name => hash_ref >> pairs. C<slot_name> can be an
array ref if you want to specify several slots the same way.

The hash ref sub-arguments are parsed thus:

=over 4

=item class

The class name of the stored object.

=item constructor_args

A array ref containing arguments that are passed to the C<new>
constructor.

=item init_method

Name of a initialisation method to call on the newly created object.
The method name defaults to C<cim_init>. In other words if the user
class feature a C<cim_init> method, this one will be called after
creation of the object.

=back

For each slot C<x>, the following methods are created:

=over 4

=item	x

A get/set method.

If supplied with an object of an appropriate type, will set set the slot
to that value.

Else, if the slot has no value, then an object is created by calling
C<new> on the appropriate class, passing in any supplied
arguments. These arguments may supersede the arguments passed with the
C<constructor_args> parameters (See above).

The stored object is then returned.

=item delete_x

Will destroy the object held by C<x>.

=item defined_x

Will return true if C<x> contains an object. False otherwise.

=back

=cut

sub translate_object_args
  {
    my @old_args = @_ ;

    warn_obsolete( "Old style object arguments are deprecated. Check documentation");

    # translate old style api
    my @new ;
    while (@old_args) 
      {
	my $obj_class = shift @old_args;

	my $list = shift @old_args or die "No slot names for obj_class";
	# Allow a list of hashrefs.
	my @list = ( ref($list) eq 'ARRAY' ) ? @$list : ($list);

	foreach my $obj_def (@list) 
	  {
	    my (@name, @c_args);
	    if ( ref $obj_def eq 'HASH') # list of hash ref
	      {
		my $slot = delete $obj_def->{slot} 
		  or die "No slot defined in object hash ref";
		push @new , $slot,  {%$obj_def, class => $obj_class} ;
	      }
	    else 
	      {
		push @new, $obj_def => $obj_class ;
	      } 
	  }
      }
    return @new ;
  }

sub object
  {
    my ($user_options, @old_args) = @_;
    my %methods;

    my $may_be_class = $old_args[0] ;

    # test whether the package name exists or not.
    my @args = defined * {$may_be_class.'::'} ? 
      translate_object_args(@old_args) : @old_args ;

    # new style API: list of hash ref
    while (@args)
      {
	my $slot_item = shift @args ;

	# Allow a list ref
	my @slot_list = ( ref($slot_item) ) ? @$slot_item : ($slot_item);

	my $arg0 = shift @args ;
	my $href = ref $arg0 ? $arg0 : {class => $arg0};
	my $c_args = $href->{constructor_args} ;
	my $slot_av = $href->{auto_vivify} ;
	my $av = defined $slot_av ? $slot_av : $user_options->{auto_vivify} ;
	my $graft = $user_options->{provide_parent_method} ;

	foreach my $slot (@slot_list)
	  {
	    # these lexicals will be used in closures
	    my $type = $href->{class} ;
	    my @c_args = defined $c_args ? @$c_args : () ;
	    my $init_method = $href->{init_method} 
	      || $user_options->{object_init_method};

	    $methods{$slot} = sub 
	      {
		my ($self, @sub_args) = @_;

		if (not defined $self->{$slot} or scalar @sub_args > 0) 
		  {
		    my $item = $sub_args[0];

		    my $obj = (ref $item and UNIVERSAL::isa($item, $type)) ?
		      $item : $av ? $type->new(@c_args) : undef ;

		    graft_parent_method($obj,$self, $slot) 
		      if $graft && defined $obj;

		    $child_init->($obj, $init_method) ;

		    # store object
		    $self->{$slot} = $obj;
		  }

		return $self->{$slot};
	      };

	    store_slot_in_catalog 
	      (
	       $slot, $user_options->{catalog_name}, 
	       slot_type => 'scalar', 
	       class => $type,
	       scalar @c_args ? (class_args => \@c_args) : ()
	      ) ;

	    $methods{"delete_$slot"} = sub {
	      my ($self) = @_;
	      $self->{$slot} = undef;
	    };

	    $methods{"defined_$slot"} = sub {
	      my ($self) = @_;
	      return defined $self->{$slot} ? 1 : 0 ;
	    };
	  }
      }
    install_methods(%methods);
  }


# ----------------------------------------------------------------------------

=head2 tie_scalar

Create a get/set method to deal with the tied scalar.

Takes a list of pairs, where the first is the name of the slot (or an
array ref containing a list of slots), the second is an array
reference.  The array reference takes the usual tie parameters.

For instance if Enum and Boolean are tied scalar that accept default values,
you can have:

  tie_scalar =>
  [
   foo => [ 'Enum',   enum => [qw/A B C/], default => 'B' ],
   bar => [ 'Enum',   enum => [qw/T0 T1/], default => 'T1'],
   baz => ['Boolean', default => 0],
   [qw/lots of slots/] => ['Boolean', default => 1],
  ],

Foreach slot C<xx>, tie_scalar install the following methods:

=over

=item tied_storage_xx

Return the object tied behind the scalar. Auto-vivify if necessary.

=back

=cut

sub tie_scalar
  {
    my ($user_options, @args) = @_;
    my %methods;

    my $parent_method_closure = $user_options->{provide_parent_method} ;

    while ( my ($fieldr, $tie_args) = splice (@args, 0, 2)) 
      {
        my ($tie_class,@c_args)= ref($tie_args) ? @$tie_args : ($tie_args);

        croak "undefined tie class" unless defined $tie_class ;

        foreach my $field_elt (ref $fieldr ? @$fieldr : $fieldr) 
          {
            my $field = $field_elt ; # safer with the closures below

            my $create_field = sub 
              {
                my $self = shift ;
                # directly tie the scalar held by self
                my $obj = tie ($self->{$field}, $tie_class, @c_args);

                graft_parent_method($obj,$self,$field) 
		  if $parent_method_closure ;
              } ;

            $methods{$field} =
              sub 
                {
                  my $self = shift ;

                  &$create_field($self) unless exists $self->{$field} ;

                  if (@_)
                    {
                      $self->{$field} = $_[0] ;
		      # avoid reading $$ref which can be a tied ref
                      return $_[0] ; 
                    }

                  return $self->{$field} ;
                };

	    my $tied_storage_sub = sub 
	      {
		my $self = shift ;
		# create the tied variable if necessary
		# (i.e. accessor was not used before)
		&$create_field($self) unless exists $self->{$field} ;

		return tied($self->{$field}) ;
	      };

            # first method provides name consistency with tie_tie_hash
	    $methods{"tied_storage_$field"} = $tied_storage_sub ;

	    foreach my $deprecated ("tied_scalar_$field",
				    "tied_$field",
				    $field."_tied")
	      {
		$methods{$deprecated} = sub
		  {
		    warn_obsolete("method $deprecated is deprecated") ;
		    return $tied_storage_sub->(@_) ;
		  } ;
	      }

            store_slot_in_catalog
              (
               $field, $user_options->{catalog_name}, 
               slot_type => 'scalar', 
               tie_scalar => $tie_class,
               scalar @c_args ? (tie_scalar_args => \@c_args) : ()
              );
          }

      }
    install_methods(%methods);
  }


sub _add_hash_methods {
  my ($methods, $field, $create_hash) = @_ ;

  croak "Missing create_hash sub" unless defined $create_hash;

  $methods->{$field . "_keys"} =
    sub {
      my ($self) = @_;
      &$create_hash($self,$field) unless defined $self->{$field} ;
      return keys %{$self->{$field}} ;
    };

  $methods->{$field . "_values"} =
    sub {
      my ($self) = @_;
      &$create_hash($self,$field) unless defined $self->{$field} ;
      values %{$self->{$field}}  ;
    };

  $methods->{$field . "_exists"} =
    sub {
      my ($self) = shift;
      my ($key) = @_;
      return
        exists $self->{$field} && exists $self->{$field}{$key};
    };

  $methods->{$field . "_delete"} =
    sub {
      my ($self, @keys) = @_;
      &$create_hash($self,$field) unless defined $self->{$field} ;
      delete @{$self->{$field}}{@keys};
    };

  $methods->{$field . "_clear"} =
    sub {
      my $self = shift;
      &$create_hash($self,$field) unless defined $self->{$field} ;
      %{$self->{$field}} = ();
    };

  $methods->{$field . "_index"} =
    sub {
      my $self = shift;
      $self->$field(@_) ;
    };

  $methods->{$field . "_set"} =
    sub {
      my $self = shift;
      &$create_hash($self,$field) unless defined $self->{$field} ;
      %{$self->{$field}} = (@_);
    };
}

# ----------------------------------------------------------------------------

=head2 hash

Creates a group of methods for dealing with hash data stored in a
slot.

 hash =>
  [
    'plain_hash1', 'plain_hash2',
    [qw/lot of plain hashes/] ,
    yet_another_plain_hash => {} ,

    my_tied_hash => {tied_hash => 'My_Tie_Hash' },
    my_tied_hash_with_args => 
      { tied_hash => [ 'My_Tie_Hash' , @my_args ] },

    my_hash_with_tied_storage => { tie_storage => 'MyTieScalar' },
    [qw/likewise_with_args likewise_with_other_args/] =>
      { tie_storage => [ 'MyTieScalar', @my_args] }

    my_tied_hash_with_tied_storage =>
      { tied_hash => 'My_Tie_Hash',tie_storage => 'MyTieScalar' },

    my_hash_with_object => { class_storage => 'MyClass' },
    my_hash_with_object_and_constructor_args =>
      { class_storage => [ 'MyClass' , @my_args ] }, 

  ]


The C<hash> parameters are:

=over

=item *

A string or a a reference to an array of strings. For each
of these string, a hash based slot is created.

=item *

A hash ref who contains attributes attached to the slot(s) defined by
the previous arguments. These attribute are used to specify the
behavior of the hash attached to the slot or to specialize the hash
values. See L<Tie::Hash::CustomStorage> for details on the possibles
attributes.

=back

For each slot defined, creates:

=over 4

=item   x

Called with no arguments returns the hash stored in the slot, as a hash
in a list context or as a reference in a scalar context.

Called with one simple scalar argument it treats the argument as a key
and returns the value stored under that key.

Called with more than one argument, treats them as a series of key/value
pairs and adds them to the hash.

=item   x_keys or x_index

Returns the keys of the hash.

=item   x_values

Returns the list of values.

=item   x_exists

Takes a single key, returns whether that key exists in the hash.

=item   x_delete

Takes a list, deletes each key from the hash.

=item	x_clear

Resets hash to empty.

=back

=cut

sub hash
  {
    my ($user_options, @args) = @_;
    my %methods;

    #print "hash called with\n", Dumper $user_options, Dumper \@args ;

    require Tie::Hash::CustomStorage ;

    my $parent_method_closure = $user_options->{provide_parent_method} ;

    while (@args) 
      {
        my $hash = shift @args ;
        my @slot_hash = ( ref($hash) eq 'ARRAY' ) ? @$hash : ($hash);

	my $x_parm = ref $args[0] ? shift @args : undef ;
	my $init_meth =  $user_options->{object_init_method} ;
        my $create_hash = sub
          {
            my ($self,$name) = @_ ;
            my %hash ;
            if (defined $x_parm)
              {
		my $init_obj = sub
		  {
		    my ($l_obj,$l_idx) = @_ ;
		    graft_parent_method($l_obj,$self,$name,$l_idx) 
		      if $parent_method_closure ;
		    $child_init->($l_obj, $init_meth) ;
		  } ;

		my $custom_tied_obj = tie %hash, 'Tie::Hash::CustomStorage', %$x_parm,
		  init_object => $init_obj ;

		my $user_tied_obj = $custom_tied_obj->get_user_tied_hash_object 
		  if defined $custom_tied_obj;
		graft_parent_method($user_tied_obj,$self,$name) 
		      if defined $user_tied_obj and $parent_method_closure ;
              }
            $self->{$name} = \%hash ;
          };

	my $handle_value = sub
          {
            my ($self,$name,$key) = splice @_,0,3 ;
            return undef unless defined $key ;

	    #print "assigning $_[0]\n";
            $self->{$name}{$key} = $_[0] if @_;
            return @_ ? $_[0] : $self->{$name}{$key};
          } ;

        foreach my $obj_def (@slot_hash) 
          {
            my $name = $obj_def; # kept for closures

            $methods{$name} = sub 
              {
                my ($self, $key) = splice @_,0,2;

                &$create_hash($self,$name) unless defined $self->{$name} ;

                return wantarray ? %{$self->{$name}} : $self->{$name}
		  unless defined $key;

		croak "hash cannot have more than 2 arg"
		  if @_ >1 ;

		$self->{$name}{$key} = $_[0] if @_;
		return @_ ? $_[0] : $self->{$name}{$key};
              };

            my $tied_hash_sub = sub 
	      {
		my $self = shift ;
		$create_hash->($self,$name) unless defined $self->{$name} ;
		my $custom_tied_obj = tied(%{$self->{$name}}) ;
		return undef unless defined $custom_tied_obj ;
		return $custom_tied_obj->get_user_tied_hash_object ;
	      } ;

	    if (defined $x_parm and defined $x_parm->{tie_hash})
	      {
		$methods{"tied_hash_$name"} = $tied_hash_sub  ;

		$methods{"tied_$name"} = 
		  sub
		    {
		      warn_obsolete( "method tied_$name is deprecated") ;
		      return $tied_hash_sub->(@_) ;
		    } ;
	      }

	    my $tied_storage_sub = sub 
                {
                  my $self = shift ;
                  my $idx = shift ;
		  &$create_hash($self,$name) unless defined $self->{$name} ;
                  &$handle_value($self,$name,$idx) ;
		  my $ref = $self->{$name} ;
		  return tied(%$ref)->get_tied_storage_object($idx) ;
                } ;

	    if (defined $x_parm and defined $x_parm->{tie_storage})
	      {
		$methods{"tied_storage_$name"} = $tied_storage_sub ;
		$methods{"tied_scalar_$name"} =  sub
		    {
		      warn_obsolete( "method tied_scalar_$name is deprecated") ;
		      return $tied_storage_sub->(@_) ;
		    } ;
	      }

	    my @info = get_extended_info($x_parm) ;

            store_slot_in_catalog($name, $user_options->{catalog_name}, 
                                          slot_type => 'hash', @info);

            _add_hash_methods(\%methods, $name,$create_hash);
          }
      }
    install_methods(%methods);
  }

sub get_extended_info
  {
    my $x_parm = shift ;

    #print Dumper $x_parm ;

    my @result = () ;
    return @result unless defined $x_parm ;

    if (defined $x_parm->{class_storage})
      {
	my $cs = $x_parm->{class_storage} ;
	my ($c,@args) =  ref $cs ? @$cs : ($cs);
	push @result, class => $c ;
	push @result, class_args => \@args if @args ;
      }

    if (defined $x_parm->{tie_storage})
      {
	my $th = $x_parm->{tie_storage} ;
	my ($c,@args)=  ref $th ? @$th : ($th);
	push @result, tie_storage => $c;
	push (@result, tie_storage_args => \@args) if scalar @args;
      }

    my $tie_index = $x_parm->{tie_hash} || $x_parm->{tie_array} ;

    if (defined $tie_index)
      {
	my ($c,@args)= ref $tie_index ? @$tie_index : ($tie_index);
	push @result, tie_index => $c;
	push (@result, tie_index_args => \@args) if scalar @args;
      }

    return @result ;
  }


sub object_tie_hash 
  {
    my ($user_options, @args) = @_;

    warn_obsolete( "object_tie_hash is deprecated. Please use hash instead");

    my @new ;
    while (@args) 
      {
	my $hash = shift @args;
	my $slot = delete $hash->{slot}
	  or croak "No slot names passef to object_tie_hash";

	$hash->{class_storage} = delete $hash->{class}
	  or croak "No class passed to object_tie_hash";

	push @new, $slot, $hash ;
      }

    hash($user_options, @new ) ;
  }


sub tie_hash 
  {
    my ($user_options, @args) = @_;

    warn_obsolete( "tie_hash is deprecated. Please use hash instead");

    my @new ;
    while (@args) 
      {
	my $slot = shift @args;
	my $hash = shift @args ;

	my $tie_class = $hash->{tie} 
	  or croak "tie_hash: missing tie parameter";
	my $tie_args = $hash->{args} ;
	my @tie_args = ref $tie_args ? @$tie_args : () ;

	push @new, $slot, { tie_hash => [ $tie_class, @tie_args] };
      }

    hash($user_options, @new ) ;
  }

sub tie_tie_hash
  {
    my ($user_options, @args) = @_;

    warn_obsolete( "tie_tie_hash is deprecated. Please use hash instead");

    my @new ;
    while (@args) 
      {
	my $hash = shift @args;
	my $slot = delete $hash->{slot}
	  or croak "No slot names passef to object_tie_hash";

	$hash->{tie_storage} = delete $hash->{tie_scalar} 
	  if defined $hash->{tie_scalar};

	push @new, $slot, $hash ;
      }

    #print Dumper \@new ;
    hash($user_options, @new ) ;
  }




sub list 
  {
    warn_obsolete("list method is obsolete. Please use array");
    goto &array ;
  }

sub _add_array_methods {
  my ($methods, $field, $create_array) = @_;

  croak "Create_array is missing" unless defined $create_array ;

  my %stock ;

  $stock{"pop"} =
      sub {
        my ($self) = @_;
	&$create_array($self,$field) unless defined $self->{$field} ;
        pop @{$self->{$field}}
      };

  $stock{"push"} =
      sub {
        my ($self, @values) = @_;
	&$create_array($self,$field) unless defined $self->{$field} ;
        push @{$self->{$field}}, @values;
      };

  $stock{"shift"} =
      sub {
        my ($self) = @_;
	&$create_array($self,$field) unless defined $self->{$field} ;
        shift @{$self->{$field}}
      };

  $stock{"unshift"} =
      sub {
        my ($self, @values) = @_;
	&$create_array($self,$field) unless defined $self->{$field} ;
        unshift @{$self->{$field}}, @values;
      };

  $stock{"splice"} =
      sub {
        my ($self, $offset, $len, @list) = @_;
	&$create_array($self,$field) unless defined $self->{$field} ;
        splice(@{$self->{$field}}, $offset, $len, @list);
      };

  $stock{"clear"} =
      sub {
        my ($self) = @_;
	&$create_array($self,$field) unless defined $self->{$field} ;
        @{$self->{$field}} = () ;
      };

  $stock{"count"} =
      sub {
        my ($self) = @_;
	&$create_array($self,$field) unless defined $self->{$field} ;
        return scalar @{$self->{$field}} ;
      };

  $stock{"storesize"} =
      sub {
        my ($self,$size) = @_;
	&$create_array($self,$field) unless defined $self->{$field} ;
	$#{$self->{$field}} = $size - 1 ;
      };

  $stock{"index"} =
      sub {
        my $self = shift;
        my (@indices) = @_;
	&$create_array($self,$field) unless defined $self->{$field} ;
        my @result = @{$self->{$field}}[@_] ;
        return $result[0] if @_ == 1;
        return wantarray ? @result : \@result;
      };

  $stock{set} =
    sub {
      my $self = shift;
      my @args = @_;
      croak "${field}_set expects an even number of fields\n"
	if @args % 2;
      &$create_array($self,$field) unless defined $self->{$field} ;
      while ( my ($index, $value) = splice @args, 0, 2 ) {
	$self->{$field}->[$index] = $value;
      }
      return @_ ;#/ 2;          # required for object_list
    };

  foreach my $op (keys %stock)
    {
      my $meth = $stock{$op} ;
      $methods->{$field.'_'.$op} = $meth ;
      $methods->{$op.'_'.$field} = sub
	{
	  warn_obsolete("${op}_$field method is obsolete. Please use ${field}_$op");
	  $meth->(@_) ;
	} ;
    }
}

=head2 array

Creates several methods for dealing with slots containing array data.

 array =>
  [
    'plain_array1', 'plain_array2',
    [qw/lot of plain arrayes/] ,
    yet_another_plain_array => {} ,

    my_tied_array => {tied_array => 'My_Tie_Array' },
    my_tied_array_with_args => 
      { tied_array => [ 'My_Tie_Array' , @my_args ] },

    my_array_with_tied_storage => { tie_storage => 'MyTieScalar' },
    [qw/likewise_with_args likewise_with_other_args/] =>
      { tie_storage => [ 'MyTieScalar', @my_args] }

    my_tied_array_with_tied_storage =>
      { tied_array => 'My_Tie_Array',tie_storage => 'MyTieScalar' },

    my_array_with_object => { class_storage => 'MyClass' },
    my_array_with_object_and_constructor_args =>
      { class_storage => [ 'MyClass' , @my_args ] }, 

  ]

The C<array> parameters are:

=over

=item *

A string or a a reference to an array of strings. For each
of these string, a array based slot is created.

=item *

A array ref who contains attributes attached to the slot(s) defined by
the previous arguments. These attribute are used to specify the
behavior of the array attached to the slot or to specialize the array
values. See L<Tie::Array::CustomStorage> for details on the possible
attributes.

=back

For each slot defined, creates:

=over 4

=item   x

This method returns the list of values stored in the slot. In an array
context it returns them as an array and in a scalar context as a
reference to the array.  If any arguments are provided to this method,
they I<replace> the current list contents.

=item   x_push

=item   x_pop

=item   x_shift

=item   x_unshift

=item   x_splice

=item   x_clear

=item   x_count

Returns the number of elements in x.

=item	x_index

Takes a list of indices, returns a list of the corresponding values.

=item	x_set

Takes a list, treated as pairs of index => value; each given index is
set to the corresponding value.  No return.

=back

=cut

sub array
  {
    my ($user_options, @args) = @_;
    my %methods;

    #print "array called with\n", Dumper $user_options, Dumper \@args ;

    require Tie::Array::CustomStorage ;

    my $parent_method_closure = $user_options->{provide_parent_method} ;

    while (@args) 
      {
        my $hash = shift @args ;
        my @slot_hash = ( ref($hash) eq 'ARRAY' ) ? @$hash : ($hash);

	my $x_parm = ref $args[0] ? shift @args : undef ;
	my $init_meth =  $user_options->{object_init_method} ;
        my $create_array = sub
          {
            my ($self,$name) = @_ ;
            my @array ;
            if (defined $x_parm)
              {
		my $init_obj = sub
		  {
		    my ($l_obj,$l_idx) = @_ ;
		    graft_parent_method($l_obj,$self,$name,$l_idx) 
		      if $parent_method_closure ;
		    $child_init->($l_obj, $init_meth) ;
		  } ;

		#print $name,':', Dumper $x_parm ;
		my $custom_tied_obj = tie @array, 'Tie::Array::CustomStorage', %$x_parm,
		  init_object => $init_obj ;

		my $user_tied_obj = $custom_tied_obj->get_user_tied_array_object 
		  if defined $custom_tied_obj;
		graft_parent_method($user_tied_obj,$self,$name) 
		      if defined $user_tied_obj and $parent_method_closure ;
              }
            $self->{$name} = \@array ;
          };

	my $handle_value = sub
          {
            my ($self,$name,$key) = splice @_,0,3 ;
            return undef unless defined $key ;

	    #print "assigning $_[0]\n";
            $self->{$name}[$key] = $_[0] if @_;
            return @_ ? $_[0] : $self->{$name}[$key];
          } ;

        foreach my $obj_def (@slot_hash) 
          {
            my $name = $obj_def; # kept for closures

            $methods{$name} = sub 
              {
                my $self = shift ;

                &$create_array($self,$name) unless defined $self->{$name} ;

		@{$self->{$name}} = @_ if @_;
		return wantarray ? @{$self->{$name}} : $self->{$name} ;
              };

            my $tied_array_sub = sub 
	      {
		my $self = shift ;
		$create_array->($self,$name) unless defined $self->{$name} ;
		my $custom_tied_obj = tied(@{$self->{$name}}) ;
		return undef unless defined $custom_tied_obj ;
		return $custom_tied_obj->get_user_tied_array_object ;
	      } ;

	    if (defined $x_parm and defined $x_parm->{tie_array})
	      {
		$methods{"tied_array_$name"} = $tied_array_sub  ;

		$methods{"tied_$name"} = 
		  sub
		    {
		      warn_obsolete( "method tied_$name is deprecated") ;
		      return $tied_array_sub->(@_) ;
		    } ;
	      }

	    my $tied_storage_sub = sub 
                {
                  my $self = shift ;
                  my $idx = shift ;
		  &$create_array($self,$name) unless defined $self->{$name} ;
                  &$handle_value($self,$name,$idx) ;
		  my $ref = $self->{$name} ;
		  return tied(@$ref)->get_tied_storage_object($idx) ;
                } ;

	    if (defined $x_parm and defined $x_parm->{tie_storage})
	      {
		$methods{"tied_storage_$name"} = $tied_storage_sub ;
		$methods{"tied_scalar_$name"} =  sub
		    {
		      warn_obsolete( "method tied_scalar_$name is deprecated") ;
		      return $tied_storage_sub->(@_) ;
		    } ;
	      }

	    my @info = get_extended_info($x_parm) ;

            store_slot_in_catalog($name, $user_options->{catalog_name}, 
                                          slot_type => 'array', @info );

            _add_array_methods(\%methods, $name, $create_array);
          }
      }
    install_methods(%methods);
  }


sub tie_list
  {
    my ($user_options, @args) = @_;
    warn_obsolete( "tie_list is deprecated. Please use array instead");

    my @new ;
    while (@args) 
      {
	my $slot = shift @args;
	my $tie_args = shift @args ;

	push @new, $slot, { tie_array => $tie_args };
      }

    #print Dumper \@new ;
    array($user_options, @new ) ;
}


sub object_list 
  {
    my ($user_options, @args) = @_;
    warn_obsolete( "tie_list is deprecated. Please use array instead");

    my @new ;
    while (@args) 
      {
	my $class = shift @args;
	my $item = shift @args ;

	my $slot = ref $item ?  delete $item->{slot} : $item
	  or croak "object_list: missing slot parameter";

	my @other =  ref $item ? %$item : () ;
	push @new, $slot, { class_storage => $class, @other };
      }

    #print Dumper \@new ;
    array($user_options, @new ) ;
}


sub object_tie_list 
  {
    my ($user_options, @args) = @_;
    warn_obsolete( "object_tie_list is deprecated. Please use array instead");

    my @new ;
    while (@args) 
      {
	my $h = shift @args ;

	my $slot = delete $h->{slot} 
	  or croak "object_tie_list: missing slot parameter";

	$h->{class_storage} = delete $h->{class} ;

	push @new, $slot, $h;
      }

    #print Dumper \@new ;
    array($user_options, @new ) ;
}


=head1 EXAMPLES

=head2 Creating an object tree

You can simply create an object with Class::IntrospectionMethods using
a CIMed class in an C<object*> method. For instance, if you want to
create a model of a school clas and their students, you can write:

 Package School_class;

 use Class::IntrospectionMethods  
   get_set => 'grade', 
   hash => 
    [ 
     student => { class_storage => 'Student'}
    ],
   new => 'new' ;

And here is the declaration of the Student class that is used in the
C<School_class> declararion :

 Package Student ;
 use Class::IntrospectionMethods  
  get_set => 'age',
  new => 'new' ;

Now you can use these lines to get and set the student attributes:

 my $son_class = School_class->new ;
 $son_class->grade('first') ;
 $son_class->student('Ginger')->age(22) ;

 my $ginger = $son_class->student('Ginger') ;
 print $ginger->age ;

=head1 BUGS

Z<>

=head1 REPORTING BUGS

Email the author.

=head1 THANKS

To Martyn J. Pearce for C<Class::MethodMaker> and the enlightening
discussion we had a while ago about parent and catalog.

To Matthew Simon Cavalletto for the parameter translation idea that I
pilfered from C<Class::MakeMethods>.

=head1  AUTHOR

Current Maintainer: Dominique Dumont domi@komarr.grenoble.hp.com

Original Authors: Martyn J. Pearce fluffy@cpan.org, Peter Seibel (Organic Online)

Contributions from:

  Evolution Online Systems, Inc. http://www.evolution.com
  Matthew Persico
  Yitzchak Scott-Thoennes

=head1 COPYRIGHT

    Copyright (c) 2004 Dominique Dumont.  This program is free
    software; you can redistribute it and/or modify it under the same terms as
    Perl itself.

    Copyright (c) 2002, 2001, 2000 Martyn J. Pearce.  This program is free
    software; you can redistribute it and/or modify it under the same terms as
    Perl itself.

    Copyright 1998, 1999, 2000 Evolution Online Systems, Inc.  You may use
    this software for free under the terms of the MIT License.  More info
    posted at http://www.evolution.com, or contact info@evolution.com

    Copyright (c) 1996 Organic Online. All rights reserved. This program is
    free software; you can redistribute it and/or modify it under the same
    terms as Perl itself.

=head1 SEE ALSO

  C<Class::Struct>, C<Class::MakeMethods>, C<Class::MethodMaker>,
  "Object-Oriented Perl" by Damian
  Conway. C<Tie::Hash::CustomStorage>, C<Tie::Array::CustomStorage>,
  C<Class::IntrospectionMethods::Parent>,
  C<Class::IntrospectionMethods::Catalog>

=cut
