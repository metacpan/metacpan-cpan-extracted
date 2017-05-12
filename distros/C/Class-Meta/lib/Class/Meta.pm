package Class::Meta;

=head1 NAME

Class::Meta - Class automation, introspection, and data validation

=head1 SYNOPSIS

Generate a class:

  package MyApp::Thingy;
  use strict;
  use Class::Meta;

  BEGIN {

      # Create a Class::Meta object for this class.
      my $cm = Class::Meta->new(
          key          => 'thingy',
          default_type => 'string',
      );

      # Add a constructor.
      $cm->add_constructor(
          name   => 'new',
          create => 1,
      );

      # Add a couple of attributes with generated methods.
      $cm->add_attribute(
          name     => 'uuid',
          authz    => 'READ',
          required => 1,
          default  => sub { Data::UUID->new->create_str },
      );
      $cm->add_attribute(
          name     => 'name',
          is       => 'string',
          default  => undef,
      );
      $cm->add_attribute(
          name    => 'age',
          is      => 'integer',
          default => undef,
      );

      # Add a custom method.
      $cm->add_method(
          name => 'chk_pass',
          view => 'PUBLIC',
          code => sub { ... },
      );

      $cm->build;
  }

  sub chck_pass { ... }

Or use Class::Meta::Express for a more pleasant declarative syntax (highly
recommended!):

  package MyApp::Thingy;
  use strict;
  use Class::Meta::Express;

  class {
      meta thingy => ( default_type => 'string' );
      ctor 'new';
      has  uuid => (
        authz    => 'READ',
        required => 1,
        deafault => sub { Data::UUID->new->create_str },
      );
      has name => ( required => 1         );
      has age  => ( is       => 'integer' );
      method chk_pass => sub { ... }
  };

Now isn't that nicer? Then use the class:

  use MyApp::Thingy;

  my $thingy = MyApp::Thingy->new( id => 19 );
  print "ID: ", $thingy->id, $/;
  $thingy->name('Larry');
  print "Name: ", $thingy->name, $/;
  $thingy->age(42);
  print "Age: ", $thingy->age, $/;

Or make use of the introspection API:

  use MyApp::Thingy;

  my $class = MyApp::Thingy->my_class;
  my $thingy;

  print "Examining object of class ", $class->package, $/;

  print "\nConstructors:\n";
  for my $ctor ($class->constructors) {
      print "  o ", $ctor->name, $/;
      $thingy = $ctor->call($class->package);
  }

  print "\nAttributes:\n";
  for my $attr ($class->attributes) {
      print "  o ", $attr->name, " => ", $attr->get($thingy), $/;
      if ($attr->authz >= Class::Meta::SET && $attr->type eq 'string') {
          $attr->get($thingy, 'hey there!');
          print "    Changed to: ", $attr->get($thingy), $/;
      }
  }

  print "\nMethods:\n";
  for my $meth ($class->methods) {
      print "  o ", $meth->name, $/;
      $meth->call($thingy);
  }

=head1 DESCRIPTION

Class::Meta provides an interface for automating the creation of Perl classes
with attribute data type validation. It differs from other such modules in
that it includes an introspection API that can be used as a unified interface
for all Class::Meta-generated classes. In this sense, it is an implementation
of the "Facade" design pattern.

=head1 USAGE

Before we get to the introspection API, let's take a look at how to create
classes with Class::Meta. Unlike many class automation modules for Perl, the
classes that Class::Meta builds do not inherit from Class::Meta. This frees
you from any dependencies on the interfaces that such a base class might
compel. For example, you can create whatever constructors you like, and name
them whatever you like.

First of all, you really want to be using
L<Class::Meta::Express|Class::Meta::Express> to declare your Class::Meta
classes. It provides a much more pleasant class declaration experience than
Class::Meta itself does. But since its functions support many of the same
arguments as the declaration methods described here, it's worth it to skim the
notes here, as well. Or if you're just a masochist and want to use the
Class::Meta interface itself, well, read on!

I recommend that you create your Class::Meta classes in a C<BEGIN> block.
Although this is not strictly necessary, it helps ensure that the classes
you're building are completely constructed and ready to go by the time
compilation has completed. Creating classes with Class::Meta is easy, using
the Class::Meta object oriented interface. Here is an example of a very simple
class:

  package MyApp::Dog;
  use strict;
  use Class::Meta;
  use Class::Meta::Types::Perl;

  BEGIN {

      # Create a Class::Meta object for this class.
      my $cm = Class::Meta->new( key => 'dog' );

      # Add a constructor.
      $cm->add_constructor(
          name   => 'new',
          create => 1,
      );

      # Add an attribute.
      $cm->add_attribute(
          name => 'tail',
          type => 'scalar',
      );

      # Add a custom method.
      $cm->add_method( name => 'wag' );
      $cm->build;
  }

  sub wag {
      my $self = shift;
      print "Wagging ", $self->tail;
  }

This simple example shows of the construction of all three types of objects
supported by Class::Meta: constructors, attributes, and methods. Here's how
it does it:

=over 4

=item *

First we load Class::Meta and Class::Meta::Types::Perl. The latter module
creates data types that can be used for attributes, including a "scalar"
data type.

=item *

Second, we create a Class::Meta object. It's okay to create it within the
C<BEGIN> block, as it won't be needed beyond that. All Class::Meta classes
have a C<key> that uniquely identifies them across an application. If none is
provided, the class name will be used, instead.

=item *

Next, we create a Class::Meta::Constructor object to describe a constructor
method for the class. The C<create> parameter to the C<add_constructor()>
method tells Class::Meta to create the constructor named "C<new()>".

=item *

Then we call C<add_attribute()> to create a single attribute, "tail". This is a
simple scalar attribute, meaning that any scalar value can be stored in
it. Class::Meta will create a Class::Meta::Attribute object that describes
this attribute, and will also shortly create accessor methods for the
attribute.

=item *

The C<add_method()> method constructs a Class::Meta::Method object to describe
any methods written for the class. In this case, we've told Class::Meta that
there will be a C<wag()> method.

=item *

And finally, we tell Class::Meta to build the class. This is the point at
which all constructors and accessor methods will be created in the class. In
this case, these include the C<new()> constructor and a C<tail()> accessor for
the "tail" attribute. And finally, Class::Meta will install another method,
C<my_class()>. This method will return a Class::Meta::Class object that
describes the class, and provides the complete introspection API.

=back

Thus, the class the above code creates has this interface:

  sub my_class;
  sub new;
  sub tail;
  sub wag;

=head2 Data Types

By default, Class::Meta loads no data types. If you attempt to create an
attribute without creating or loading the appropriate data type, you will
get an error.

But I didn't want to leave you out in the cold, so I created a whole bunch of
data types to get you started. Any of these will automatically be loaded by
Class::Meta if it is used to create an attribute. They can also be loaded
simply by C<use>ing the appropriate module. The modules are:

=over 4

=item L<Class::Meta::Types::Perl|Class::Meta::Types::Perl>

Typical Perl data types.

=over 4

=item scalar

Any scalar value.

=item scalarref

A scalar reference.

=item array

=item arrayref

An array reference.

=item hash

=item hashref

A hash reference.

=item code

=item coderef

=item closure

A code reference.

=back

=item L<Class::Meta::Types::String|Class::Meta::Types::String>

=over 4

=item string

Attributes of this type must contain a string value. Essentially, this means
anything other than a reference.

=back

=item L<Class::Meta::Types::Boolean|Class::Meta::Types::Boolean>

=over 4

=item boolean

=item bool

Attributes of this type store a boolean value. Implementation-wise, this means
either a 1 or a 0.

=back

=item L<Class::Meta::Types::Numeric|Class::Meta::Types::Numeric>

These data types are validated by the functions provided by
L<Data::Types|Data::Types>.

=over 4

=item whole

A whole number.

=item integer

An integer.

=item decimal

A decimal number.

=item real

A real number.

=item float

a floating point number.

=back

=back

Other data types may be added in the future. See the individual data type
modules for more information.

=head2 Accessors

Class::Meta supports the creation of three different types of attribute
accessors: typical Perl single-method accessors, "affordance" accessors, and
"semi-affordance" accessors. The single accessors are named for their
attributes, and typically tend to look like this:

  sub tail {
      my $self = shift;
      return $self->{tail} unless @_;
      return $self->{tail} = shift;
  }

Although this can be an oversimplification if the data type has associated
validation checks.

Affordance accessors provide at up to two accessors for every attribute: One
to set the value and one to retrieve the value. They tend to look like this:

  sub get_tail { shift->{tail} }

  sub set_tail { shift->{tail} = shift }

These accessors offer a bit less overhead than the traditional Perl accessors,
in that they don't have to check whether they're called to get or set a
value. They also have the benefit of creating a psychological barrier to
misuse. Since traditional Perl accessors I<can> be created as read-only or
write-only accessors, one can't tell just by looking at them which is the
case. The affordance accessors make this point moot, as they make clear what
their purpose is.

Semi-affordance accessors are similar to affordance accessors in that they
provide at least two accessors for every attribute. However, the accessor that
fetches the value is named for the attribute. Thus, they tend to look like
this:

  sub tail { shift->{tail} }

  sub set_tail { shift->{tail} = shift }

To get Class::Meta's data types to create affordance accessors, simply pass
the string "affordance" to them when you load them:

  use Class::Meta::Types::Perl 'affordance';

Likewise, to get them to create semi-affordance accessors, pass the string
"semi-affordance":

  use Class::Meta::Types::Perl 'semi-affordance';

The boolean data type is the only one that uses a slightly different approach
to the creation of affordance accessors: It creates three of them. Assuming
you're creating a boolean attribute named "alive", it will create these
accessors:

  sub is_alive      { shift->{alive} }
  sub set_alive_on  { shift->{alive} = 1 }
  sub set_alive_off { shift->{alive} = 0 }

Incidentally, I stole the term "affordance" from Damian Conway's "Object
Oriented Perl," pp 83-84, where he borrows it from Donald Norman.

See L<Class::Meta::Type|Class::Meta::Type> for details on creating new data
types.

=head2 Introspection API

Class::Meta provides four classes the make up the introspection API for
Class::Meta-generated classes. Those classes are:

=head3 L<Class::Meta::Class|Class::Meta::Class>

Describes the class. Each Class::Meta-generated class has a single constructor
object that can be retrieved by calling a class' C<my_class()> class
method. Using the Class::Meta::Class object, you can get access to all of the
other objects that describe the class. The relevant methods are:

=over 4

=item constructors

Provides access to all of the Class::Meta::Constructor objects that describe
the class' constructors, and provide indirect access to those constructors.

=item attributes

Provides access to all of the Class::Meta::Attribute objects that describe the
class' attributes, and provide methods for indirectly getting and setting
their values.

=item methods

Provides access to all of the Class::Meta::Method objects that describe the
class' methods, and provide indirect execution of those constructors.

=back

=head3 L<Class::Meta::Constructor|Class::Meta::Constructor>

Describes a class constructor. Typically a class will have only a single
constructor, but there could be more, and client code doesn't necessarily know
its name. Class::Meta::Constructor objects resolve these issues by describing
all of the constructors in a class. The most useful methods are:

=over 4

=item name

Returns the name of the constructor, such as "new".

=item call

Calls the constructor on an object, passing in the arguments passed to
C<call()> itself.

=back

=head3 L<Class::Meta::Attribute|Class::Meta::Attribute>

Describes a class attribute, including its name and data type. Attribute
objects are perhaps the most useful Class::Meta objects, in that they can
provide a great deal of information about the structure of a class. The most
interesting methods are:

=over 4

=item name

Returns the name of the attribute.

=item type

Returns the name of the attribute's data type.

=item required

Returns true if the attribute is required to have a value.

=item once

Returns true if the attribute value can be set to a defined value only once.

=item set

Sets the value of an attribute on an object.

=item get

Returns the value of an attribute on an object.

=back

=head3 L<Class::Meta::Method|Class::Meta::Method>

Describes a method of a class, including its name and context (class
vs. instance). The relevant methods are:

=over 4

=item name

The method name.

=item context

The context of the method indicated by a value corresponding to either
Class::Meta::OBJECT or Class::Meta::CLASS.

=item call

Calls the method, passing in the arguments passed to C<call()> itself.

=back

Consult the documentation of the individual classes for a complete description
of their interfaces.

=cut

##############################################################################
# Class Methods
##############################################################################

=head1 INTERFACE

=head2 Class Methods

=head3 default_error_handler

  Class::Meta->default_error_handler($code);
  my $default_error_handler = Class::Meta->default_error_handler;

Sets the default error handler for Class::Meta classes. If no C<error_handler>
attribute is passed to new, then this error handler will be associated with
the new class. The default default error handler uses C<Carp::croak()> to
handle errors.

Note that if other modules are using Class::Meta that they will use your
default error handler unless you reset the default error handler to its
original value before loading them.

=head3 handle_error

  Class::Meta->handle_error($err);

Uses the code reference returned by C<default_error_handler()> to handle an
error. Used internally Class::Meta classes when no Class::Meta::Class object
is available. Probably not useful outside of Class::Meta unless you're
creating your own accessor generation class. Use the C<handle_error()>
instance method in Class::Meta::Class, instead.

=head3 for_key

  my $class = Class::Meta->for_key($key);

Returns the Class::Meta::Class object for a class by its key name. This can be
useful in circumstances where the key has been used to track a class, and you
need to get a handle on that class. With the class package name, you can of
course simply call C<< $pkg->my_class >>; this method is the solution for
getting the class object for a class key.

=head3 keys

  my @keys = Class::Meta->keys;

Returns the keys for all Class::Meta::Class objects.  The order of keys is
not guaranteed.  In scalar context, this method returns an array reference
containing the keys.

=head3 clear

  Class::Meta->clear;
  Class::Meta->clear($key);

Called without arguments, C<clear> will remove all
L<Class::Meta::Class|Class::Meta::Class> objects from memory. Called with an
argument, C<clear> attempts to remove only that key from memory. Calling it
with a non-existent key is a no-op.

In general, you probably won't want to use this method, except perhaps in
tests, when you might need to do funky things with your classes.

=cut

##############################################################################
# Constructors                                                               #
##############################################################################

=head2 Constructors

=head3 new

  my $cm = Class::Meta->new( key => $key );

Constructs and returns a new Class::Meta object that can then be used to
define and build the complete interface of a class. Many of the supported
parameters values will default to values specified for the most immediate
Class::Meta-built parent class, if any. The supported parameters are:

=over 4

=item package

The package that defines the class. Defaults to the package of the code
that calls C<new()>.

=item key

A key name that uniquely identifies a class within an application. Defaults to
the value of the C<package> parameter if not specified.

=item name

The human name to use for the class. Defaults to the value of C<key> with
underscores replaced with spaces and each word capitalized by the C<ucfirst>
operator. So "foo" will become "Foo" and "contact_type" will become "Contact
Type".

=item abstract

A boolean indicating whether the class being defined is an abstract class. An
abstract class, also known as a "virtual" class, is not intended to be used
directly. No objects of an abstract class should every be created. Instead,
classes that inherit from an abstract class must be implemented.

=item default_type

A data type to use for attributes added to the class with no explicit data
type. See L</"Data Types"> for some possible values for this parameter.
Inheritable from parent class.

=item trust

An array reference of key names or packages that are trusted by the class.

  trust => ['Foo::Bar', 'Foo::Bat'],

Trusted packages and the classes that inherit from them can retrieve trusted
attributes and methods of the class. Trusted packages need not be Class::Meta
classes. Trusted classes do not include the declaring class by default, so if
you want the class that declares an attribute to be able to use trusted
attribute accessors, be sure to include it in the list of trusted packages:

  trust => [__PACKAGE__, 'Foo::Bar', 'Foo::Bat'],

If you need to trust a single class, you may pass in the key name or package
of that class rather than an array reference:

  trust => 'Foo::Bar',

=item class_class

The name of a class that inherits from Class::Meta::Class to be used to create
all of the class objects for the class. Defaults to Class::Meta::Class.
Inheritable from parent class.

=item constructor_class

The name of a class that inherits from Class::Meta::Constructor to be used to
create all of the constructor objects for the class. Defaults to
Class::Meta::Constructor. Inheritable from parent class.

=item attribute_class

The name of a class that inherits from Class::Meta::Attribute to be used to
create all of the attribute objects for the class. Defaults to
Class::Meta::Attribute. Inheritable from parent class.

=item method_class

The name of a class that inherits from Class::Meta::Method to be used to
create all of the method objects for the class. Defaults to
Class::Meta::Method. Inheritable from parent class.

=item error_handler

A code reference that will be used to handle errors thrown by the methods
created for the new class. Defaults to the value returned by C<<
Class::Meta->default_error_handler >>. Inheritable from parent class.

=back

=cut

##############################################################################
# Dependencies                                                               #
##############################################################################
use 5.006001;
use strict;
use Class::ISA ();

##############################################################################
# Constants                                                                  #
##############################################################################

# View. These determine who can get metadata objects back from method calls.
use constant PRIVATE   => 0x01;
use constant PROTECTED => 0x02;
use constant TRUSTED   => 0x03;
use constant PUBLIC    => 0x04;

# Authorization. These determine what kind of accessors (get, set, both, or
# none) are available for a given attribute or method.
use constant NONE      => 0x01;
use constant READ      => 0x02;
use constant WRITE     => 0x03;
use constant RDWR      => 0x04;

# Method generation. These tell Class::Meta which accessors to create. Use
# NONE above for NONE. These will use the values in the authz argument by
# default. They're separate because sometimes an accessor needs to be built
# by hand, rather than custom-generated by Class::Meta, and the
# authorization needs to reflect that.
use constant GET       => READ;
use constant SET       => WRITE;
use constant GETSET    => RDWR;

# Method and attribute context.
use constant CLASS     => 0x01;
use constant OBJECT    => 0x02;

# Parameters passed on to subclasses.
use constant INHERITABLE => qw(
    class_class
    error_handler
    attribute_class
    method_class
    constructor_class
    default_type
);

##############################################################################
# Dependencies that rely on the above constants                              #
##############################################################################
use Class::Meta::Type;
use Class::Meta::Class;
use Class::Meta::Constructor;
use Class::Meta::Attribute;
use Class::Meta::Method;

##############################################################################
# Package Globals                                                            #
##############################################################################
our $VERSION = '0.66';

##############################################################################
# Private Package Globals
##############################################################################
CLASS: {
    my (%classes, %keys);
    my $error_handler = sub {
        require Carp;
        our @CARP_NOT = qw(
            Class::Meta
            Class::Meta::Attribute
            Class::Meta::Constructor
            Class::Meta::Method
            Class::Meta::Type
            Class::Meta::Types::Numeric
            Class::Meta::Types::String
            Class::Meta::AccessorBuilder
        );
        # XXX Make sure Carp doesn't point to Class/Meta/Constructor.pm when
        # an exception is thrown by Class::Meta::AccessorBuilder. I have no
        # idea why this is necessary for AccessorBuilder but nowhere else!
        # Damn Carp.
        @Class::Meta::AccessorBuilder::CARP_NOT = @CARP_NOT
          if caller(1) eq 'Class::Meta::AccessorBuilder';
        Carp::croak(@_);
    };

    sub default_error_handler {
        shift;
        return $error_handler unless @_;
        $error_handler->("Error handler must be a code reference")
          unless ref $_[0] eq 'CODE';
        return $error_handler = shift;
    }

    sub handle_error {
        shift;
        $error_handler->(@_);
    }

    sub for_key { $keys{ $_[1] } }
    sub keys    { wantarray ? keys %keys : [keys %keys] }
    sub clear   { shift; @_ ? delete $keys{+shift} : undef %keys }

    sub new {
        my $pkg = shift;

        # Make sure we can get all the arguments.
        $error_handler->(
            "Odd number of parameters in call to new() when named "
            . "parameters were expected"
        ) if @_ % 2;
        my %p = @_;

        # Class defaults to caller. Key defaults to class.
        $p{package} ||= caller;
        $p{key} ||= $p{package};

        # Find any parent C::M class.
        for my $super ( Class::ISA::super_path( $p{package} ) ) {
            next unless $super->can('my_class');
            # Copy attributes.
            my $parent = $super->my_class;
            for my $param (INHERITABLE) {
                $p{$param} = $parent->{$param} unless exists $p{$param};
            }
            last;
        }

        # Configure the error handler.
        if (exists $p{error_handler}) {
            $error_handler->("Error handler must be a code reference")
              unless ref $p{error_handler} eq 'CODE';
        } else {
            $p{error_handler} = $pkg->default_error_handler;
        }

        # Check to make sure we haven't created this class already.
        $p{error_handler}->(
            "Class object for class '$p{package}' already exists"
        ) if $classes{$p{package}};

        $p{class_class}       ||= 'Class::Meta::Class';
        $p{constructor_class} ||= 'Class::Meta::Constructor';
        $p{attribute_class}   ||= 'Class::Meta::Attribute';
        $p{method_class}      ||= 'Class::Meta::Method';

        # Instantiate and cache Class object.
        $keys{$p{key}} = $classes{$p{package}} = $p{class_class}->new(\%p);

        # Copy its parents' attributes.
        $classes{$p{package}}->_inherit( \%classes, 'attr');

        # Return!
        return bless { package => $p{package} } => ref $pkg || $pkg;
    }

##############################################################################
# add_constructor()

=head3 add_constructor

  $cm->add_constructor(
      name   => 'construct',
      create => 1,
  );

Creates and returns a Class::Meta::Constructor object that describes a
constructor for the class. The supported parameters are:

=over 4

=item name

The name of the constructor. The name must consist of only alphanumeric
characters or "_". Required.

=item create

When true, Class::Meta::Constructor will automatically create and install a
constructor named for the C<name> parameter. Defaults to true unless C<code>
is passed. In general you won't need to specify this parameter unless you've
written your own constructor in the package, in which case you'll want to
specify C<< create => 0 >>.

=item label

A label for the constructor. Generally used for displaying its name in a user
interface. Optional.

=item desc

A description of the constructor. Possibly useful for displaying help text in
a user interface. Optional.

=item code

You can implicitly define the constructor in your class by passing a code
reference via the C<code> parameter. Once C<build()> is called,
L<Kinetic::Meta::Constructor|Kinetic::Meta::Constructor> will install the
constructor into the package for which the Class::Meta object was defined, and
with the name specified via the C<name> parameter. Note that if the
constructor view is PRIVATE or PROTECTED, the constructor will be wrapped in
extra code to constrain the view. Optional.

=item view

The visibility of the constructor. The possible values are defined by the
following constants:

=over 4

=item Class::Meta::PUBLIC

Can be used by any client.

=item Class::Meta::PRIVATE

Can only be used by the declaring class.

=item Class::Meta::TRUSTED

Can only be used by the classes specified by the C<trust> parameter to
C<new()>.

=item Class::Meta::PROTECTED

Can only be used by the declaring class or by classes that inherit from it.

=back

Defaults to Class::Meta::PUBLIC if not defined. You can also use strings
aliases to the above constants, although the constant values will actually be
stored in the L<Class::Meta::Constructor|Class::Meta::Constructor> object,
rather than the string. The supported strings are "PUBLIC", "PRIVATE",
"TRUSTED", and "PROTECTED".

=item caller

A code reference that calls the constructor. Defaults to a code reference that
calls a method with the name provided by the C<name> attribute on the class
being defined.

=back

If Class::Meta creates the constructor, it will be a simple parameter-list
constructor, wherein attribute values can be passed as a list of
attribute-name/value pairs, e.g.:

  my $thingy = MyApp::Thingy->new(
      name => 'Larry',
      age  => 32,
  );

Required attributes must have a value passed to the constructor, with one
exception: You can pass an optional subroutine reference as the last argument
to the constructor. After all parameter values and default values have been
set on the object, but before any exceptions are thrown for undefined required
attributes, the constructor will execute this subroutine reference, passing in
the object being constructed as the sole argument. So, for example, if C<name>
is required but, for some reason, could not be set before constructing the
object, you could set it like so:

  my $thingy = MyApp::Thingy->new(
      age  => 32,
      sub {
          my $thingy = shift;
          # age and attributes with default values are already set.
          my $name = calculate_name( $thingy );
          $thingy->name($name);
      },
  );

This allows developers to have a scope-limited context in which to work before
required constraints are enforced.

=cut

    sub add_constructor {
        my $class = $classes{ shift->{package} };
        push @{$class->{build_ctor_ord}},
          $class->{constructor_class}->new($class, @_);
        return $class->{build_ctor_ord}[-1];
    }

##############################################################################
# add_attribute()

=head3 add_attribute

  $cm->add_attribute(
      name => 'tail',
      type => 'scalar',
  );

Creates and returns a Class::Meta::Attribute object that describes an
attribute of the class. The supported parameters are:

=over 4

=item name

The name of the attribute. The name must consist of only alphanumeric
characters or "_". Required.

=item type

=item is

The data type of the attribute. See L</"Data Types"> for some possible values
for this parameter. If the type name corresponds to a data type in a package
in the Class::Meta::Types name space, that package will automatically be
loaded and configured with Perl-style accessors, so that the data type can
simply be used. If both C<type> and C<is> are passed, C<is> will be used.
Required unless the class was declared with a C<default_type>.

=item required

A boolean value indicating whether the attribute is required to have a value.
Defaults to false.

=item once

A boolean value indicating whether the attribute can be set to a defined value
only once. Defaults to false.

=item label

A label for the attribute. Generally used for displaying its name in a user
interface. Optional.

=item desc

A description of the attribute. Possibly useful for displaying help text in a
user interface. Optional.

=item view

The visibility of the attribute. See the description of the C<view> parameter
to C<add_constructor> for a description of its value.

=item authz

The authorization of the attribute. This value indicates whether it is
read-only, write-only, read/write, or inaccessible. The possible values are
defined by the following constants:

=over 4

=item Class::Meta::READ

=item Class::Meta::WRITE

=item Class::Meta::RDWR

=item Class::Meta::NONE

=back

Defaults to Class::Meta::RDWR if not defined. You can also use strings aliases
to the above constants, although the constant values will actually be stored
in the L<Class::Meta::Attribute|Class::Meta::Attribute> object, rather than
the string. The supported strings are "READ", "WRITE", "RDWR", and "NONE".

=item create

Indicates what type of accessor or accessors are to be created for the
attribute.

=over 4

=item Class::Meta::GET

Create read-only accessor(s).

=item Class::Meta::SET

Create write-only accessor(s).

=item Class::Meta::GETSET

Create read/write accessor(s).

=item Class::Meta::NONE

Create no accessors.

=back

You can also use strings aliases to the above constants, although the constant
values will actually be stored in the
L<Class::Meta::Attribute|Class::Meta::Attribute> object, rather than the
string. The supported strings are "GET", "SET", "GETSET", and "NONE".

If not unspecified, the value of the C<create> parameter will correspond to
the value of the C<authz> parameter like so:

  authz       create
  ------------------
  READ   =>   GET
  WRITE  =>   SET
  RDWR   =>   GETSET
  NONE   =>   NONE

The C<create> parameter differs from the C<authz> parameter in case you've
taken it upon yourself to create some accessors, and therefore don't need
Class::Meta to do so. For example, if you were using standard Perl-style
accessors, and needed to do something a little different by coding your own
accessor, you'd specify it like this:

  $cm->add_attribute(
      name   => $name,
      type   => $type,
      authz  => Class::Meta::RDWR,
      create => Class::Meta::NONE
  );

Just be sure that your custom accessor compiles before you call
C<< $cm->build >> so that Class::Meta::Attribute can get a handle on it for
its C<get()> and/or C<set()> methods.

=item context

The context of the attribute. This indicates whether it's a class attribute or
an object attribute. The possible values are defined by the following
constants:

=over 4

=item Class::Meta::CLASS

=item Class::Meta::OBJECT

=back

You can also use strings aliases to the above constants, although the constant
values will actually be stored in the
L<Class::Meta::Attribute|Class::Meta::Attribute> object, rather than the
string. The supported strings are "CLASS", and "OBJECT".

=item default

The default value for the attribute, if any. This may be either a literal
value or a code reference that will be executed to generate a default value.

=item override

If an attribute being added to a class has the same name as an attribute in a
parent class, Class::Meta will normally throw an exception. However, in some
cases you might want to override an attribute in a parent class to change its
properties. In such a case, pass a true value to the C<override> parameter to
override the attribute and avoid the exception.

=back

=cut

    sub add_attribute {
        my $class = $classes{ shift->{package} };
        push @{$class->{build_attr_ord}},
          $class->{attribute_class}->new($class, @_);
        return $class->{build_attr_ord}[-1];
    }

##############################################################################
# add_method()

=head3 add_method

  $cm->add_method( name => 'wag' );

Creates and returns a Class::Meta::Method object that describes a method of
the class. The supported parameters are:

=over 4

=item name

The name of the method. The name must consist of only alphanumeric
characters or "_".

=item label

A label for the method. Generally used for displaying its name in a user
interface. Optional.

=item desc

A description of the method. Possibly useful for displaying help text in a
user interface. Optional.

=item view

The visibility of the method. See the description of the C<view> parameter to
C<add_constructor> for a description of its value. Class::Meta only enforces
the C<view> if the C<code> parameter is used to define the method body.
Otherwise, it's up to the class implementation itself to do the job.

=item code

You can implicitly define the method in your class by passing a code reference
via the C<code> parameter. Once C<build()> is called,
L<Kinetic::Meta::Method|Kinetic::Meta::Method> will install the method into
the package for which the Class::Meta object was defined, and with the name
specified via the C<name> parameter. If the C<view> is anything other than
PUBLIC, it will be enforced.

=item context

The context of the method. This indicates whether it's a class method or an
object method. See the description of the C<context> parameter to C<add_attribute>
for a description of its value.

=item caller

A code reference that calls the method. This code reference will be be used by
the C<call()> method of L<Class::Meta::Method|Class::Meta::Method> to execute
the method on behalf of an object. Defaults to a code reference that calls a
method with the name provided by the C<name> attribute on the class being
defined.

=item args

A description of the arguments to the method. This can be anything you like,
but I recommend something like a string for a single argument, an array
reference for a list of arguments, or a hash reference for parameter
arguments.

=item returns

A string describing the return value or values of the method.

=back

=cut

    sub add_method {
        my $class = $classes{ shift->{package} };
        push @{$class->{build_meth_ord}},
          $class->{method_class}->new($class, @_);
        return $class->{build_meth_ord}[-1];
    }

##############################################################################
# Instance Methods                                                           #
##############################################################################

=head2 Instance Methods

=head3 class

  my $class = $cm->class;

Returns the instance of the Class::Meta::Class object that will be used to
provide the introspection API for the class being generated.

=cut

    # Simple accessor.
    sub class { $classes{ $_[0]->{package} } }

##############################################################################
# build()

=head3 build

  $cm->build;

Builds the class defined by the Class::Meta object, including the
C<my_class()> class method, and all requisite constructors and accessors.

=cut

    sub build {
        my $self = shift;
        my $class = $classes{ $self->{package} };

        # Build the attribute accessors.
        if (my $attrs = delete $class->{build_attr_ord}) {
            $_->build($class) for @$attrs;
        }

        # Build the constructors.
        if (my $ctors = delete $class->{build_ctor_ord}) {
            $_->build(\%classes) for @$ctors;
        }

        # Build the methods.
        if (my $meths = delete $class->{build_meth_ord}) {
            $_->build(\%classes) for @$meths;
        }

        # Build the class; it needs to get at the data added by the above
        # calls to build() methods.
        $class->build(\%classes);

        # Build the Class::Meta::Class accessor and key shortcut.
        no strict 'refs';
        *{"$class->{package}::my_class"} = sub { $class };

        return $self;
    }
}

# Trusted function to convert strings to their constant values.
sub _str_to_const {
    my $val = shift;
    return $val if !$val || $val !~ /\w/;
    my $view = eval "Class::Meta::\U$val" or return $val;
    return $view;
}

1;
__END__

=head1 JUSTIFICATION

One might argue that there are already too many class automation and parameter
validation modules on CPAN. And one would be right. They range from simple
accessor generators, such as L<Class::Accessor|Class::Accessor>, to simple
parameter validators, such as L<Params::Validate|Params::Validate>, to more
comprehensive systems, such as L<Class::Contract|Class::Contract> and
L<Class::Tangram|Class::Tangram>. But, naturally, none of them could do
exactly what I needed.

What I needed was an implementation of the "Facade" design pattern. Okay, this
isn't a facade like the "Gang of Four" meant it, but it is in the respect that
it creates classes with a common API so that objects of these classes can all
be used identically, calling the same methods on each. This is done via the
implementation of an introspection API. So the process of creating classes
with Class::Meta not only creates attributes and accessors, but also creates
objects that describe those classes. Using these descriptive objects, client
applications can determine what to do with objects of Class::Meta-generated
classes. This is particularly useful for user interface code.

=head1 TO DO

=over 4

=item *

Add support for an C<accessor> parameter to C<add_attribute()> that will be
used for the accessor instead of generating one.

=item *

Make class attribute accessors behave as they do in Class::Data::Inheritable.

=item *

Modify class attribute accessors so that they are thread safe. This will
involve sharing the attributes across threads, and locking them before
changing their values. If they've also been made to behave as they do in
Class::Data::Inheritable, we'll have to figure out a way to make it so that
newly generated accessors for subclasses are shared between threads, too. This
may not be easy.

=back

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/class-meta/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/class-meta/issues/> or by sending mail to
L<bug-Class-Meta@rt.cpan.org|mailto:bug-Class-Meta@rt.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 SEE ALSO

First of all, use L<Class::Meta::Express|Class::Meta::Express> instead of
Class::Meta to declare your classes. I hope I've made that clear enough by
now.

Other classes of interest within the Class::Meta distribution include:

=over 4

=item L<Class::Meta::Class|Class::Meta::Class>

=item L<Class::Meta::Constructor|Class::Meta::Constructor>

=item L<Class::Meta::Attribute|Class::Meta::Attribute>

=item L<Class::Meta::Method|Class::Meta::Method>

=item L<Class::Meta::Type|Class::Meta::Type>

=item L<Class::Meta::Types::Perl|Class::Meta::Types::Perl>

=item L<Class::Meta::Types::String|Class::Meta::Types::String>

=item L<Class::Meta::Types::Boolean|Class::Meta::Types::Boolean>

=item L<Class::Meta::Types::Numeric|Class::Meta::Types::Numeric>

=back

For comparative purposes, you might also want to check out these fine modules:

=over

=item L<Class::Accessor|Class::Accessor>

Accessor and constructor automation.

=item L<Params::Validate|Params::Validate>

Parameter validation.

=item L<Class::Contract|Class::Contract>

Design by contract.

=item L<Class::Tangram|Class::Tangram>

Accessor automation and data validation for Tangram applications.

=item L<Class::Maker|Class::Maker>

An ambitious yet under-documented module that also manages accessor and
constructor generation, data validation, and provides a reflection API. It
also supports serialization.

=item L<Class::MOP|Class::MOP>

Stevan Little's application of Perl 6 meta classes to Perl 5.

=item L<Moose|Moose>

"It's the new camel." Another extension of the Perl 5 object system, built on
Class::MOP.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
