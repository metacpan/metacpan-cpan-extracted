package Class::Meta::Type;

=head1 NAME

Class::Meta::Type - Data type validation and accessor building.

=head1 SYNOPSIS

  package MyApp::TypeDef;

  use strict;
  use Class::Meta::Type;
  use IO::Socket;

  my $type = Class::Meta::Type->add(
      key  => 'io_socket',
      desc => 'IO::Socket object',
      name => 'IO::Socket Object'
  );

=head1 DESCRIPTION

This class stores the various data types us
ed by C<Class::Meta>. It manages
all aspects of data type validation and method creation. New data types can be
added to Class::Meta::Type by means of the C<add()> constructor. This is
useful for creating custom types for your Class::Meta-built classes.

B<Note:>This class manages the most advanced features of C<Class::Meta>.
Before deciding to create your own accessor closures as described in L<add()>,
you should have a thorough working knowledge of how Class::Meta works, and
have studied the L<add()> method carefully. Simple data type definitions such
as that shown in the L<SYNOPSIS>, on the other hand, are encouraged.

=cut

##############################################################################
# Dependencies                                                               #
##############################################################################
use strict;

##############################################################################
# Package Globals                                                            #
##############################################################################
our $VERSION = '0.66';

##############################################################################
# Private Package Globals                                                    #
##############################################################################
my %def_builders = (
    'default'         => 'Class::Meta::AccessorBuilder',
    'affordance'      => 'Class::Meta::AccessorBuilder::Affordance',
    'semi-affordance' => 'Class::Meta::AccessorBuilder::SemiAffordance',
);

# This code ref builds object/reference value checkers.
my $class_validation_generator = sub {
    my ($pkg, $type) = @_;
    return [
        sub {
            return unless defined $_[0];
            UNIVERSAL::isa($_[0], $pkg)
              or $_[2]->class->handle_error(
                  "Value '$_[0]' is not a valid $type"
              );
            }
    ];
};

##############################################################################
# Data type definition storage.
##############################################################################
{
    my %types = ();

##############################################################################
# Constructors                                                               #
##############################################################################

=head1 CONSTRUCTORS

=head2 new

  my $type = Class::Meta::Type->new($key);

Returns the data type definition for an existing data type. The definition
will be looked up by the C<$key> argument. Use C<add()> to specify new types.
If no data type exists for a given key, but C<< Class::Meta->for_key >>
returns a Class::Meta::Class object for that key, then C<new()> will
implicitly call C<add()> to create add a new type corresponding to that
class. This makes it easy to use any Class::Meta class as a data type.

Other data types can be added by means of the C<add()> constructor, or by
simply C<use>ing one or more of the following modules:

=over 4

=item L<Class::Meta::Types::Perl|Class::Meta::Types::Perl>

=over 4

=item scalar

=item scalarref

=item array

=item hash

=item code

=back

=item L<Class::Meta::Types::String|Class::Meta::Types::String>

=over 4

=item string

=back

=item L<Class::Meta::Types::Boolean|Class::Meta::Types::Boolean>

=over 4

=item boolean

=back

=item L<Class::Meta::Types::Numeric|Class::Meta::Types::Numeric>

=over 4

=item whole

=item integer

=item decimal

=item real

=item float

=back

=back

Read the documentation for the individual modules for details on their data
types.

=cut

    sub new {
        my $class = shift;
        Class::Meta->handle_error('Type argument required') unless $_[0];
        my $key = lc shift;
        unless (exists $types{$key}) {
            # See if there's a Class::Meta class defined for this key.
            my $cmc = Class::Meta->for_key($key)
              or Class::Meta->handle_error("Type '$key' does not exist");

            # Create a new type for this class.
            return $class->add(
                key   => $key,
                name  => $cmc->package,
                check => $cmc->package
            );
        }
        return bless $types{$key}, $class;
    }

##############################################################################

=head2 add

  my $type = Class::Meta::Type->add(
      key  => 'io_socket',
      name => 'IO::Socket Object',
      desc => 'IO::Socket object'
  );

Creates a new data type definition and stores it for future use. Use this
constructor to add new data types to meet the needs of your class. The named
parameter arguments are:

=over 4

=item key

Required. The key with which the data type can be looked up in the future via
a call to C<new()>. Note that the key will be used case-insensitively, so
"foo", "Foo", and "FOO" are equivalent, and the key must be unique.

=item name

Required. The name of the data type. This should be formatted for display
purposes, and indeed, Class::Meta will often use it in its own exceptions.

=item check

Optional. Specifies how to validate the value of an attribute of this type.
The check parameter can be specified in any of the following ways:

=over 4

=item *

As a code reference. When Class::Meta executes this code reference, it will
pass in the value to check, the object for which the attribute will be set,
and the Class::Meta::Attribute object describing the attribute. If the
attribute is a class attribute, then the second argument will not be an
object, but a hash reference with two keys:

=over 8

=item $name

The existing value for the attribute is stored under the attribute name.

=item __pkg

The name of the package to which the attribute is being assigned.

=back

If the new value is not the proper value for your custom data type, the code
reference should throw an exception. Here's an example; it's the code
reference used by "string" data type, which you can add to Class::Meta::Type
simply by using Class::Meta::Types::String:

  check => sub {
      my $value = shift;
      return unless defined $value && ref $value;
      require Carp;
      our @CARP_NOT = qw(Class::Meta::Attribute);
      Carp::croak("Value '$value' is not a valid string");
  }

Here's another example. This code reference might be used to make sure that a
new value is always greater than the existing value.

  check => sub {
      my ($new_val, $obj, $attr) = @_;
      # Just return if the new value is greater than the old value.
      return if defined $new_val && $new_val > $_[1]->{$_[2]->get_name};
      require Carp;
      our @CARP_NOT = qw(Class::Meta::Attribute);
      Carp::croak("Value '$new_val' is not greater than '$old_val'");
  }

=item *

As an array reference. All items in this array reference must be code
references that perform checks on a value, as specified above.

=item *

As a string. In this case, Class::Meta::Type assumes that your data type
identifies a particular object type. Thus it will use the string to construct
a validation code reference for you. For example, if you wanted to create a
data type for IO::Socket objects, pass the string 'IO::Socket' to the check
parameter and Class::Meta::Type will use the code reference returned by
C<class_validation_generator()> to generate the validation checks. If you'd
like to specify an alternative class validation code generator, pass one to
the C<class_validation_generator()> class method. Or pass in a code reference
or array reference of code reference as just described to use your own
validator once.

=back

Note that if the C<check> parameter is not specified, there will never be any
validation of your custom data type. And yes, there may be times when you want
this -- The default "scalar" and "boolean" data types, for example, have no
checks.

=item builder

Optional. This parameter specifies the accessor builder for attributes of this
type. The C<builder> parameter can be any of the following values:

=over 4

=item "default"

The string 'default' uses Class::Meta::Type's default accessor building code,
provided by Class::Meta::AccessorBuilder. This is the default value, of
course.

=item "affordance"

The string 'default' uses Class::Meta::Type's affordance accessor building
code, provided by Class::Meta::AccessorBuilder::Affordance. Affordance
accessors provide two accessors for an attribute, a C<get_*> accessor and a
C<set_*> mutator. See
L<Class::Meta::AccessorBuilder::Affordance|Class::Meta::AccessorBuilder::Affordance>
for more information.

=item "semi-affordance"

The string 'default' uses Class::Meta::Type's semi-affordance accessor
building code, provided by Class::Meta::AccessorBuilder::SemiAffordance.
Semi-affordance accessors differ from affordance accessors in that they do not
prepend C<get_> to the accessor. So for an attribute "foo", the accessor would
be named C<foo()> and the mutator named C<set_foo()>. See
L<Class::Meta::AccessorBuilder::SemiAffordance|Class::Meta::AccessorBuilder::SemiAffordance>
for more information.

=item A Package Name

Pass in the name of a package that contains the functions C<build()>,
C<build_attr_get()>, and C<build_attr_set()>. These functions will be used to
create the necessary accessors for an attribute. See L<Custom Accessor
Building|"Custom Accessor Building"> for details on creating your own accessor
builders.

=back

=back

=cut

    sub add {
        my $pkg = shift;
        # Make sure we can process the parameters.
        Class::Meta->handle_error(
            'Odd number of parameters in call to new() when named '
                . 'parameters were expected'
            ) if @_ % 2;

        my %params = @_;

        # Check required paremeters.
        foreach (qw(key name)) {
            Class::Meta->handle_error("Parameter '$_' is required")
                unless $params{$_};
        }

        # Check the key parameter.
        $params{key} = lc $params{key};
        Class::Meta->handle_error("Type '$params{key}' already defined")
          if exists $types{$params{key}};

        # Set up the check croak.
        my $chk_die = sub {
            Class::Meta->handle_error(
              "Paremter 'check' in call to add() must be a code reference, "
               . "an array of code references, or a scalar naming an object "
               . "type"
           );
        };

        # Check the check parameter.
        if ($params{check}) {
            my $ref = ref $params{check};
            if (not $ref) {
                # It names the object to be checked. So generate a validator.
                $params{check} =
                  $class_validation_generator->(@params{qw(check name)});
                $params{check} = [$params{check}]
                  if ref $params{check} eq 'CODE';
            } elsif ($ref eq 'CODE') {
                $params{check} = [$params{check}]
            } elsif ($ref eq 'ARRAY') {
                # Make sure that they're all code references.
                foreach my $chk (@{$params{check}}) {
                    $chk_die->() unless ref $chk eq 'CODE';
                }
            } else {
                # It's bogus.
                $chk_die->();
            }
        }

        # Check the builder parameter.
        $params{builder} ||= $pkg->default_builder;

        my $builder = $def_builders{$params{builder}} || $params{builder};
        # Make sure it's loaded.
        eval "require $builder" or die $@;

        $params{builder} = UNIVERSAL::can($builder, 'build')
          || Class::Meta->handle_error("No such function "
                                        . "'${builder}::build()'");

        $params{attr_get} = UNIVERSAL::can($builder, 'build_attr_get')
          || Class::Meta->handle_error("No such function "
                                        . "'${builder}::build_attr_get()'");

        $params{attr_set} = UNIVERSAL::can($builder, 'build_attr_set')
          || Class::Meta->handle_error("No such function "
                                        . "'${builder}::build_attr_set()'");

        # Okay, add the new type to the cache and construct it.
        $types{$params{key}} = \%params;

        # Grab any aliases.
        if (my $alias = delete $params{alias}) {
            if (ref $alias) {
                $types{$_} = \%params for @$alias;
            } else {
                $types{$alias} = \%params;
            }
        }
        return $pkg->new($params{key});
    }
}

##############################################################################

=head1 CLASS METHODS

=head2 default_builder

  my $default_builder = Class::Meta::Type->default_builder;
  Class::Meta::Type->default_builder($default_builder);

Get or set the default builder class attribute. The value can be any one of
the values specified for the C<builder> parameter to add(). The value set in
this attribute will be used for the C<builder> parameter to to add() when none
is explicitly passed. Defaults to "default".

=cut

my $default_builder = 'default';
sub default_builder {
    my $pkg = shift;
    return $default_builder unless @_;
    $default_builder = shift;
    return $pkg;
}

##############################################################################

=head2 class_validation_generator

  my $gen = Class::Meta::Type->class_validation_generator;
  Class::Meta::Type->class_validation_generator( sub {
      my ($pkg, $name) = @_;
      return sub {
          die "'$pkg' is not a valid $name"
            unless UNIVERSAL::isa($pkg, $name);
      };
  });

Gets or sets a code reference that will be used to generate the validation
checks for class data types. That is to say, it will be used when a string is
passed to the C<checks> parameter to <add()> to generate the validation
checking code for data types that are objects. By default, it will generate a
validation checker like this:

  sub {
      my $value = shift;
      return if UNIVERSAL::isa($value, 'IO::Socket')
      require Carp;
      our @CARP_NOT = qw(Class::Meta::Attribute);
      Carp::croak("Value '$value' is not a IO::Socket object");
  };

But if you'd like to specify an alternate validation check generator--perhaps
you'd like to throw exception objects rather than use Carp--just pass a code
reference to this class method. The code reference should expect two
arguments: the data type value to be validated, and the string passed via the
C<checks> parameter to C<add()>. It should return a code reference or array of
code references that validate the value. For example, you might want to do
something like this to throw exception objects:

  use Exception::Class('MyException');

  Class::Meta::Type->class_validation_generator( sub {
      my ($pkg, $type) = @_;
      return [ sub {
          my ($value, $object, $attr) = @_;
          MyException->throw("Value '$value' is not a valid $type")
            unless UNIVERSAL::isa($value, $pkg);
      } ];
  });

But if the default object data type validator is good enough for you, don't
worry about it.

=cut

sub class_validation_generator {
    my $class = shift;
    return $class_validation_generator unless @_;
    $class_validation_generator = shift;
}

##############################################################################
# Instance methods.
##############################################################################

=head1 INTERFACE

=head2 Instance Methods

=head3 key

  my $key = $type->key;

Returns the key name for the type.

=head3 name

  my $name = $type->name;

Returns the type name.

=head3 check

  my $checks = $type->check;
  my @checks = $type->check;

Returns an array reference or list of the data type validation code references
for the data type.

=cut

sub key  { $_[0]->{key}  }
sub name { $_[0]->{name} }
sub check  {
    return unless $_[0]->{check};
    wantarray ? @{$_[0]->{check}} : $_[0]->{check}
}

##############################################################################

=head3 build

This is a protected method, designed to be called only by the
Class::Meta::Attribute class or a subclass of Class::Meta::Attribute. It
creates accessors for the class that the Class::Meta::Attribute object is a
part of by calling out to the C<build()> method of the accessor builder class.

Although you should never call this method directly, subclasses of
Class::Meta::Type may need to override its behavior.

=cut

sub build {
    # Check to make sure that only Class::Meta or a subclass is building
    # attribute accessors.
    my $caller = caller;
    Class::Meta->handle_error("Package '$caller' cannot call "
                                         . __PACKAGE__ . "->build")
      unless UNIVERSAL::isa($caller, 'Class::Meta::Attribute');

    my $self = shift;
    my $code = $self->{builder};
    $code->(@_, $self->check);
    return $self;
}

##############################################################################

=head3 make_attr_set

This is a protected method, designed to be called only by the
Class::Meta::Attribute class or a subclass of Class::Meta::Attribute. It
returns a reference to the attribute set accessor (mutator) created by the
call to C<build()>, and usable as an indirect attribute accessor by the
Class::Meta::Attribute C<set()> method.

Although you should never call this method directly, subclasses of
Class::Meta::Type may need to override its behavior.

=cut

sub make_attr_set {
    my $self = shift;
    my $code = $self->{attr_set};
    $code->(@_);
}

##############################################################################

=head3 make_attr_get

This is a protected method, designed to be called only by the
Class::Meta::Attribute class or a subclass of Class::Meta::Attribute. It
returns a reference to the attribute get accessor created by the call to
C<build()>, and usable as an indirect attribute accessor by the
Class::Meta::Attribute C<get()> method.

Although you should never call this method directly, subclasses of
Class::Meta::Type may need to override its behavior.

=cut

sub make_attr_get {
    my $self = shift;
    my $code = $self->{attr_get};
    $code->(@_);
}

1;
__END__

=head1 CUSTOM DATA TYPES

Creating custom data types can be as simple as calling C<add()> and passing in
the name of a class for the C<check> parameter. This is especially useful when
you just need to create attributes that contain objects of a particular type,
and you're happy with the accessors that Class::Meta will create for you. For
example, if you needed a data type for a DateTime object, you can set it
up--complete with validation of the data type, like this:

  my $type = Class::Meta::Type->add(
      key   => 'datetime',
      check => 'DateTime',
      desc  => 'DateTime object',
      name  => 'DateTime Object'
  );

From then on, you can create attributes of the type "datetime" without any
further work. If you wanted to use affordance accessors, you'd simply
add the requisite C<builder> attribute:

  my $type = Class::Meta::Type->add(
      key     => 'datetime',
      check   => 'DateTime',
      builder => 'affordance',
      desc    => 'DateTime object',
      name    => 'DateTime Object'
  );

The same goes for using semi-affordance accessors.

Other than that, adding other data types is really a matter of the judicious
use of the C<check> parameter. Ultimately, all attributes are scalar
values. Whether they adhere to a particular data type depends entirely on the
validation code references passed via C<check>. For example, if you wanted to
create a "range" attribute with only the allowed values 1-5, you could do it
like this:

  my $range_chk = sub {
      my $value = shift;
      die "Value is not a number" unless $value =~ /^[1..5]$/;
  };

  my $type = Class::Meta::Type->add(
      key   => 'range',
      check => $range_chk,
      desc  => 'Pick a number between 1 and 5',
      name  => 'Range (1-5)'
  );

Of course, the above value validator will throw an exception with the
line number from which C<die> is called. Even better is to use L<Carp|Carp>
to throw an error with the file and line number of the client code:

  my $range_chk = sub {
      my $value = shift;
      return if $value =~ /^[1..5]$/;
      require Carp;
      our @CARP_NOT = qw(Class::Meta::Attribute);
      Carp::croak("Value is not a number");
  };

The C<our @CARP_NOT> line prevents the context from being thrown from within
Class::Meta::Attribute, which is useful if you make use of that class'
C<set()> method.

=head2 Custom Accessor Building

Class::Meta also allows you to craft your own accessors. Perhaps you'd prefer
to use a StudlyCaps affordance accessor standard. In that case, you'll need to
create your own module that builds accessors. I recommend that you study
L<Class::Meta::AccessorBuilder|Class::Meta::AccessorBuilder> and
L<Class::Meta::AccessorBuilder::Affordance|Class::Meta::AccessorBuilder::Affordance>
before taking on creating your own.

Custom accessor building modules must have three functions.

=head3 build

The C<build()> function creates and installs the actual accessor methods in a
class. It should expect the following arguments:

  sub build {
      my ($class, $attribute, $create, @checks) = @_;
      # ...
  }

These are:

=over 4

=item C<$class>

The name of the class into which the accessors are to be installed.

=item C<$attribute>

A Class::Meta::Attribute object representing the attribute for which accessors
are to be created. Use it to determine what types of accessors to create
(read-only, write-only, or read/write, class or object), and to add checks for
required constraints and accessibility (if the attribute is private, trusted,
or protected).

=item C<$create>

The value of the C<create> parameter passed to Class::Meta::Attribute when the
attribute object was created. Use this argument to determine what type of
accessor(s) to create. See L<Class::Meta::Attribute|Class::Meta::Attribute>
for the possible values for this argument.

=item C<@checks>

A list of one or more data type validation code references. Use these in any
accessors that set attribute values to check that the new value has a valid
value.

=back

See L<Class::Meta::AccessorBuilder|Class::Meta::AccessorBuilder> for example
attribute creation functions.

=head3 build_attr_get and build_attr_set

The C<build_attr_get()> and C<build_attr_set()> functions take a single
argument, a Class::Meta::Attribute object, and return code references that
either represent the corresponding methods, or that call the appropriate
accessor methods to get and set an attribute, respectively. The code
references will be used by Class::Meta::Attribute's C<get()> and
C<set()> methods to get and set attribute values. Again, see
L<Class::Meta::AccessorBuilder|Class::Meta::AccessorBuilder> for examples
before creating your own.

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

Other classes of interest within the Class::Meta distribution include:

=over 4

=item L<Class::Meta|Class::Meta>

This class contains most of the documentation you need to get started with
Class::Meta.

=item L<Class::Meta::Attribute|Class::Meta::Attribute>

This class manages Class::Meta class attributes, all of which are based on
data types.

=back

These modules provide some data types to get you started:

=over 4

=item L<Class::Meta::Types::Perl|Class::Meta::Types::Perl>

=item L<Class::Meta::Types::String|Class::Meta::Types::String>

=item L<Class::Meta::Types::Boolean|Class::Meta::Types::Boolean>

=item L<Class::Meta::Types::Numeric|Class::Meta::Types::Numeric>

=back

The modules that Class::Meta comes with for creating accessors are:

=over 4

=item L<Class::Meta::AccessorBuilder|Class::Meta::AccessorBuilder>

Standard Perl-style accessors.

=item L<Class::Meta::AccessorBuilder::Affordance|Class::Meta::AccessorBuilder::Affordance>

Affordance accessors--that is, explicit and independent get and set accessors.

=item L<Class::Meta::AccessorBuilder::SemiAffordance|Class::Meta::AccessorBuilder::SemiAffordance>

Semi-affordance accessors--that is, independent get and set accessors with an
explicit set accessor.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
