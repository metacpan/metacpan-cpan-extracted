package Class::Meta::Declare;

use warnings;
use strict;
use Class::Meta;
use Class::BuildMethods qw/
  accessors
  cm
  /;

=head1 NAME

Class::Meta::Declare - Deprecated in favor of Class::Meta::Express

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

This was a first attempt at making a saner interface for
L<Class::Meta|Class::Meta>.  It I<is> nicer, but
L<Class::Meta::Express|Class::Meta::Express> is nicer still.  Go use that one.

 package MyApp::Thingy;
 use Class::Meta::Declare ':all';
 use Data::UUID;

 Class::Meta::Declare->new(
     meta       => [
         key       => 'thingy',
         accessors => $ACC_SEMI_AFFORDANCE,
     ],
     attributes => [
         pi => {
             context => $CTXT_CLASS,
             authz   => $AUTHZ_READ,
             default => 3.1415927,
         },
         id => {
             authz   => $AUTHZ_READ,
             type    => $TYPE_STRING,
             default => sub { Data::UUID->new->create_str },
         },
         name => {
             required => 1,
             type     => $TYPE_STRING,
             default  => 'No Name Supplied',
         },
         age => { type => $TYPE_INTEGER, },
     ],
     methods => [
         some_method => {
             view => $VIEW_PUBLIC,
             code => sub {
                 my $self = shift;
                 return [ reverse @_ ];
             },
         }
     ]
 );

 my $object = MyApp::Thingy->new;
 print MyApp::Thingy->pi;  # prints 3.1415927
 print $object->name;      # prints "No Name Supplied';
 $object->set_name("bob");
 print $object->name;      # prints "bob"

=head1 DESCRIPTION

This class provides an alternate interface for C<Class::Meta>.

C<Class::Meta> is a useful module which allows one to create Perl classes
which support I<introspection> (also known as I<reflection>). Typically Perl
classes, when created, don't supply a lot of metadata. Imported helper
functions show up when you call C<< $object->can($method) >>. Private,
protected and trusted methods are not readily supported. Fetching a list of
attributes or methods is a haphazard affair. C<Class::Meta> overcomes these
shortcomings by building the classes for you and allowing you to fetch a class
object:

  my $class_object = $object->my_class;

  foreach my $attribute ( $class_object->attributes ) {
      print $attribute->name, "\n";
  }
  foreach my $method ( $class_object->methods ) {
      print $method->name, "\n";
  }

If you've set up your class correctly, these properties are now easy to
discover.

Unfortunately, many find the C<Class::Meta> interface to be a bit clumsy. As
an alternative, C<Class::Meta::Declare> allows you to declare your entire
class in a single argument list to the constructor and have the class built
for you automatically. Further, reasonable defaults are provided for just
about everything.

B<IMPORTANT>: You want this class or C<Class::Meta> if you need an
introspection API for your classes. If you do not need introspection or
dynamic class generation, these modules are overkill.

=head1 COMPARISON TO CLASS::META

Consider the C<Class::Meta::Declare> example from the C<SYNOPSIS>:

 package MyApp::Thingy;
 use Class::Meta::Declare ':all';
 use Data::UUID;

 Class::Meta::Declare->new(
     meta       => [
        key       => 'thingy',
        accessors => $ACC_SEMI_AFFORDANCE,
     ],
     attributes => [
         pi => {
             context => $CTXT_CLASS,
             authz   => $AUTHZ_READ,
             default => 3.1415927,
         },
         id => {
             authz   => $AUTHZ_READ,
             type    => $TYPE_INTEGER,
             default => sub { Data::UUID->new->create_str },
         },
         name => {
             required => 1,
             type     => $TYPE_STRING,
             default  => 'No Name Supplied',
         },
         age => { type => $TYPE_INTEGER, },
     ],
     methods => [
         some_method => {
             view => $VIEW_PUBLIC,
             code => sub {
                 my $self = shift;
                 return [ reverse @_ ];
             },
         }
     ]
 );

Here's the equivalent C<Class::Meta> code:

 package MyApp::Thingy;
 use Class::Meta;
 use Class::Meta::Types::String 'semi-affordance';
 use Class::Meta::Types::Numeric 'semi-affordance';
 use Data::UUID;

 my $cm = Class::Meta->new( key => 'thingy' );

 $cm->add_constructor(
     name   => 'new',
     create => 1,
 );

 $cm->add_attribute(
     name    => 'pi',
     context => Class::Meta::CLASS,
     authz   => Class::Meta::READ,
     type    => 'whole',
     default => 3.1415927,
 );

 $cm->add_attribute(
     name    => 'id',
     authz   => Class::Meta::READ,
     type    => 'integer',
     default => sub { Data::UUID->new->create_str },
 );

 $cm->add_attribute(
     name     => 'name',
     required => 1,
     type     => 'string',
     default  => 'No Name Supplied',
 );

 $cm->add_attribute(
     name => 'age',
     type => 'integer',
 );

 sub some_method {
     my $self = shift;
     return [ reverse @_ ];
 }

 $cm->add_method(
     name => 'some_method',
     view => Class::Meta::PUBLIC,
 );

 $cm->build;

As you can see, the C<Class::Meta> code is longer.  The larger and more
complicated the class, the longer it gets.  C<Class::Meta::Declare> offers the
following advantages:

=over 4

=item * Shorter code

=item * Compile-time failures for many mistyped attribute values

=item * Less duplication of information (for example, see C<add_method>)

=item * Helper classes for included C<Class::Meta> types are autoloaded

=item * Sensible defaults for many entries

=back

=cut

use Readonly;

# ACC

Readonly our $ACC_PERL            => '';
Readonly our $ACC_AFFORDANCE      => 'affordance';
Readonly our $ACC_SEMI_AFFORDANCE => 'semi-affordance';

# AUTHZ

Readonly our $AUTHZ_READ  => Class::Meta::READ;
Readonly our $AUTHZ_WRITE => Class::Meta::WRITE;
Readonly our $AUTHZ_RDWR  => Class::Meta::RDWR;
Readonly our $AUTHZ_NONE  => Class::Meta::NONE;

# CREATE

Readonly our $CREATE_GET    => Class::Meta::GET;
Readonly our $CREATE_SET    => Class::Meta::SET;
Readonly our $CREATE_GETSET => Class::Meta::GETSET;
Readonly our $CREATE_NONE   => Class::Meta::NONE;

# CTXT

Readonly our $CTXT_CLASS  => Class::Meta::CLASS;
Readonly our $CTXT_OBJECT => Class::Meta::OBJECT;

# TYPE

Readonly our $TYPE_SCALAR    => 'scalar';
Readonly our $TYPE_SCALARREF => 'scalarref';
Readonly our $TYPE_ARRAY     => 'array';
Readonly our $TYPE_ARRAYREF  => 'arrayref';
Readonly our $TYPE_HASH      => 'hash';
Readonly our $TYPE_HASHREF   => 'hashref';
Readonly our $TYPE_CODE      => 'code';
Readonly our $TYPE_CODEREF   => 'coderef';
Readonly our $TYPE_CLOSURE   => 'closure';
Readonly our $TYPE_STRING    => 'string';
Readonly our $TYPE_BOOLEAN   => 'boolean';
Readonly our $TYPE_BOOL      => 'bool';
Readonly our $TYPE_WHOLE     => 'whole';
Readonly our $TYPE_INTEGER   => 'integer';
Readonly our $TYPE_DECIMAL   => 'decimal';
Readonly our $TYPE_REAL      => 'real';
Readonly our $TYPE_FLOAT     => 'float';

# VIEW

Readonly our $VIEW_PUBLIC    => Class::Meta::PUBLIC;
Readonly our $VIEW_PRIVATE   => Class::Meta::PRIVATE;
Readonly our $VIEW_TRUSTED   => Class::Meta::TRUSTED;
Readonly our $VIEW_PROTECTED => Class::Meta::PROTECTED;

# start type lookup

my %TYPE_CLASS_FOR = map { $_ => 'Class::Meta::Types::Perl' } (
    $TYPE_SCALAR,   $TYPE_SCALARREF, $TYPE_ARRAY,
    $TYPE_ARRAYREF, $TYPE_HASH,      $TYPE_HASHREF,
    $TYPE_CODE,     $TYPE_CODEREF,   $TYPE_CLOSURE,
);
$TYPE_CLASS_FOR{$TYPE_STRING}  = 'Class::Meta::Types::String';
$TYPE_CLASS_FOR{$TYPE_BOOL}    = 'Class::Meta::Types::Boolean';
$TYPE_CLASS_FOR{$TYPE_BOOLEAN} = 'Class::Meta::Types::Boolean';

foreach my $type (
    $TYPE_WHOLE, $TYPE_INTEGER, $TYPE_DECIMAL, $TYPE_REAL,
    $TYPE_FLOAT
  )
{
    $TYPE_CLASS_FOR{$type} = 'Class::Meta::Types::Numeric';
}

# end type lookup

use Exporter::Tidy acc => [
    qw/
      $ACC_PERL
      $ACC_AFFORDANCE
      $ACC_SEMI_AFFORDANCE
      /
  ],
  authz => [
    qw/
      $AUTHZ_READ
      $AUTHZ_WRITE
      $AUTHZ_RDWR
      $AUTHZ_NONE
      /
  ],
  create => [
    qw/
      $CREATE_GET
      $CREATE_SET
      $CREATE_GETSET
      $CREATE_NONE
      /
  ],
  ctxt => [
    qw/
      $CTXT_CLASS
      $CTXT_OBJECT
      /
  ],
  type => [
    qw/
      $TYPE_SCALAR
      $TYPE_SCALARREF
      $TYPE_ARRAY
      $TYPE_ARRAYREF
      $TYPE_HASH
      $TYPE_HASHREF
      $TYPE_CODE
      $TYPE_CODEREF
      $TYPE_CLOSURE
      $TYPE_STRING
      $TYPE_BOOLEAN
      $TYPE_BOOL
      $TYPE_WHOLE
      $TYPE_INTEGER
      $TYPE_DECIMAL
      $TYPE_REAL
      $TYPE_FLOAT
      /
  ],
  view => [
    qw/
      $VIEW_PUBLIC
      $VIEW_PRIVATE
      $VIEW_TRUSTED
      $VIEW_PROTECTED
      /
  ];

##############################################################################

=head1 CLASS METHODS

=head2 new

  Class::Meta::Declare->new(%options);

The C<new> method allows you to build an entire class, with reflective
capabilities, just like C<Class::Meta>.  However, the syntax is shorter,
hopefully clearer, and it builds everything in one go.

See C<CONSTRUCTOR OPTIONS> for details on C<%options>.

=cut

sub new {
    my $class = shift;
    my $self  = $class->_init(@_);
    $self->cm->build;
    return $self;
}

##############################################################################

=head2 create

  my $declare = Class::Meta::Declare->create(\%options);
  my $class_meta = $declare->cm;
  # more Class::Meta stuff
  $class_meta->build;

This constructor is exactly the same as C<new> except it does not call
C<Class::Meta>'s C<build> method. Use this constructor if you have more stuff
you need to do prior to C<build> being called.

=cut

sub create {
    my $class = shift;
    my $self  = $class->_init(@_);
    return $self;
}

sub _init {
    my $class           = shift;
    my $self            = bless {}, $class;
    my %declaration_for = @_;
    foreach my $type (qw/meta constructors attributes methods/) {
        $declaration_for{$type} ||= [];
    }
    if ( exists $declaration_for{constructors}
        && @{ $declaration_for{constructors} } )
    {
        push @{ $declaration_for{meta} }, _no_constructor => 1;
    }
    $self->_set_cm( delete $declaration_for{meta} );
    $self->_add_constructors( delete $declaration_for{constructors} );
    $self->_add_attributes( delete $declaration_for{attributes} );
    $self->_add_methods( delete $declaration_for{methods} );
    return $self;
}

##############################################################################

=head1 INSTANCE METHODS

=head2 cm

 my $cm = $declare->cm;

Returns the C<Class::Meta> object used to build the the class.

=head2 installed_types

 my @types = $declare->installed_types;
 if ($declare->installed_types('Class::Meta::Type::Numeric')) { ... }

Returns a list of data types used.  If passed a data type, returns a boolean
value indicating whether or not that type was used.

=cut

{
    my %is_installed;

    sub installed_types {
        my $self = shift;
        $is_installed{ $self->accessors } ||= {};
        return sort keys %{ $is_installed{ $self->accessors } } unless @_;
        return $is_installed{ $self->accessors }{ +shift };
    }

    sub _set_installed {
        my ( $self, $package ) = @_;
        $is_installed{ $self->accessors }{$package} = 1;
    }
}

##############################################################################

=head2 package

  my $package = $declare->package;

Returns the package for which the C<Class::Meta> code was declared.

=cut

sub package { shift->cm->class->package }

sub _set_cm {
    my ( $self, $meta ) = @_;
    my %value_for = @$meta;

    $value_for{package} ||= $self->_get_call_pack;
    $self->accessors( delete $value_for{accessors} || $ACC_PERL );
    my $build = delete $value_for{use} || 'Class::Meta';
    eval "use $build";
    if ( my $error = $@ ) {
        $self->_croak("Cannot use $build as building class: $error");
    }

    my $cm = $build->new(%value_for);

    # If they've defined their own constructors, we had better not build a
    # default.
    unless ( $value_for{_no_constructor} ) {
        $cm->add_constructor(
            name   => 'new',
            create => 1
        );
    }
    $self->cm($cm);
    return $self;
}

sub _get_call_pack {
    my $self = shift;

    my $call_level = 1;
    my $call_pack;
    while ( !$call_pack ) {
        ($call_pack) = caller($call_level);
        last unless $call_pack;
        $call_level++;
        undef $call_pack if $call_pack->isa(__PACKAGE__);
    }
    return $call_pack
      or $self->_croak("Could not determine package");
}

sub _add_constructors {
    my ( $self, $constructors ) = @_;
    while ( my $constructor = shift @$constructors ) {
        my $definition_for = shift @$constructors;
        $definition_for->{name} = $constructor;
        $definition_for->{create} = exists $definition_for->{code} ? 0 : 1;
        if ( my $code = delete $definition_for->{code} ) {
            $self->_install_method( $constructor, $code );
        }
        $self->cm->add_constructor(%$definition_for);
    }
    return $self;
}

sub _add_attributes {
    my ( $self, $attributes ) = @_;

    while ( my $attribute = shift @$attributes ) {
        my $definition_for = shift @$attributes;

        # set defaults
        $definition_for->{name} = $attribute;
        $definition_for->{type} = $TYPE_SCALAR
          unless exists $definition_for->{type};

        # figure out the class for the type
        my $type_class = $TYPE_CLASS_FOR{ $definition_for->{type} };
        unless ($type_class) {
            my $class = Class::Meta->for_key( $definition_for->{type} );
            $type_class = $class->package if $class;
        }
        $self->_croak("Could not find type class for $definition_for->{type}")
          unless defined $type_class;

        # set attribute interface type (e.g., 'affordance')
        unless ( $self->installed_types($type_class) ) {
            my $accessors = $self->accessors;
            $accessors = "'$accessors'" if $accessors;
            eval "use $type_class $accessors";
            if ( my $error = $@ ) {
                $self->_croak("Could not load $type_class: $error");
            }
            $self->_set_installed($type_class);
        }

        # add the attributes
        if ( exists $definition_for->{code} ) {
            $self->_install_attribute_code(
                $attribute,
                delete $definition_for->{code}
            );
            $definition_for->{create} = $CREATE_NONE;
        }

        eval { $self->cm->add_attribute(%$definition_for) };
        if ( my $error = $@ ) {
            $self->_croak("Setting attribute for $attribute failed: $error");
        }
    }
    return $self;
}

sub _add_methods {
    my ( $self, $methods ) = @_;

    while ( my $name = shift @$methods ) {
        my $definition_for = shift @$methods;
        if ( exists $definition_for->{code} ) {

            # the "code" slot is not required as the sub may already exist via
            # direct implementation or via "autoload".
            $self->_install_method( $name, delete $definition_for->{code} );
        }
        $definition_for->{name} = $name;
        eval { $self->cm->add_method(%$definition_for) };
        if ( my $error = $@ ) {
            $self->_croak("Adding method for $name failed: $error");
        }
    }
    return $self;
}

my %accessor_builder_for = (
    $ACC_PERL            => \&_install_perl_accessors,
    $ACC_SEMI_AFFORDANCE => \&_install_affordance_accessors,
    $ACC_AFFORDANCE      => \&_install_affordance_accessors,
);

sub _install_attribute_code {
    my ( $self, $attribute, $code ) = @_;
    my $code_installer = $accessor_builder_for{ $self->accessors }
      or $self->_croak(
        "I don't know how to install methods for @{[$self->accessors]}");
    $self->$code_installer( $attribute, $code );
    return $self;
}

sub _install_method {
    my ( $self, $method, $code ) = @_;
    unless ( 'CODE' eq ref $code ) {
        $self->_croak("Value for $method is not a coderef");
    }
    my $package = $self->package;
    no strict 'refs';
    *{"${package}::$method"} = $code;
}

sub _install_perl_accessors {
    my ( $self, $attribute, $code ) = @_;
    unless ( 'CODE' eq ref $code ) {
        $self->_croak(
            "'code' value for Perl-style accessors must be a coderef");
    }
    $self->_install_method( $attribute, $code );
    return $self;
}

sub _install_affordance_accessors {
    my ( $self, $attribute, $code ) = @_;
    my $accessor_style = $self->accessors;
    unless ( 'HASH' eq ref $code ) {
        $self->_croak(
            "'code' value for $accessor_style accessors must be a hashref");
    }
    my $get_prefix = $accessor_style =~ /^semi/ ? '' : 'get_';
    my $get = $code->{get}
      or $self->_croak("No 'get' method supplied for $attribute");
    $self->_install_method( "$get_prefix$attribute", $get );
    my $set = $code->{set}
      or $self->_croak("No 'set' method supplied for $attribute");
    $self->_install_method( "set_$attribute", $set );
    return $self;
}

sub _croak {
    my ( $class, $message ) = @_;
    require Carp;
    Carp::croak $message;
}

=head1 CONSTRUCTOR OPTIONS

The constructor takes an even-sized list of name/value declarations. Each name
should be one of C<meta>, C<constructors>, C<attributes> or C<methods>.  Each
declaration should be an array reference of with key/value pairs in it (in
other words, it's like a hashref but because it's in an array reference, we
preserve the element order).  Each key is optional, but supplying no keys
pretty much means you have an empty class (though you will get a default
constructor).

The following lists the key/value options for each declaration.

=head2 meta

Note that all keys for C<meta> are optional.

=over 4

=item * key

This specifies the "class key" underwhich you may fetch a new instance of a
class object:

 my $class_object = Class::Meta->for_key($key);

See L<Class::Meta|Class::Meta>'s "for_key".

=item * package

Building a class assumes the class is to be built in the current package.  You
may override this with a package parameter.

 meta => [
   key     => 'foo',
   package => 'Foo',
 ]

=item * accessors

This key specifies the getter/setter style which will be built for attributes.
Perl-style getter/setters look like this:

 my $name = $object->name;
 $object->name('Bob');

You may also specify "semi-affordance" style accessors with
C<$ACC_SEMI_AFFORDANCE>:

 my $name = $object->name;
 $object->set_name('Bob');

You may also specify "affordance" style accessors with
C<$ACC_AFFORDANCE>:

 my $name = $object->get_name;
 $object->set_name('Bob');

This meta declaration thus might look like this:

 meta => [
   accessors => $ACC_SEMI_AFFORDANCE
 ]

Note that the accessors parameter has no value on data types not supplied by
C<Class::Meta> unless they have been written to recognize them.

=item * use

By default, we assume that C<Class::Meta> is the build class.  If you have
subclassed C<Class::Meta> (or done something really bizarre like creating an
alternative with an identical interface), you may specify that class with the
C<use> key:

 meta => [
   use => "Class::Meta::Subclass",
 ]

Note that C<Class::Meta::Declare> is an alternate interface, not a subclass of
C<Class::Meta>.

=back

=head3 C<meta> defaults

=over 4

=item * C<accessors>

C<$ACC_PERL>

=item * C<key>

Defaults to value of C<package> key.

=item * C<package>

Calling package.

=item * C<use>

C<Class::Meta>

=back

=head2 constructors

By default, a C<new> constructor is created for you.  If you pass a
C<constructors> declaration, the default constructor will not be built and all
constructor creation will be up to you.

Each constructor must have a key which specifies the name of the constructor
and point to a hashref containing additional information about the
constructor.  An empty hashref will simply create a constructor with the given
name, so the default constructor which is provided by C<Class::Meta::Declare>
in the absense of a C<constructors> declaration is simply:

 constructors => [
    new => {}
 ]

The values of the hashref should match the values identified in the
C<Class::Meta> "add_constructor" documentation.  C<name> is not required (and
will be ignored if supplied) as name is taken from the hashref key.  C<view>
should be on of the values listed in the C<EXPORT> ":view" section of this
documentation.

The actual body of the constructor, if supplied, should be provided with the
C<code> key.

So to create factory constructor, one might do this (the following example
assumes that the two factory classes listed are subclasses of the current
class):

 package MyClass;
 use Class::Meta::Declare;
 Class::Meta::Declare->new(
   constructors => [
     new     => {}, # we can have multiple constructors
     factory => {
       view => $VIEW_PUBLIC, # optional as this is the default
       code => sub {
         my ($class, $target) = @_;
         $class = $target eq 'foo'
           ? 'Subclass::Foo'
           : 'Subclass::Bar';
         return bless {}, $class;
       }
     }
   ]

And later you'll be able to do this:

 my $object = MyClass->new;
 print ref $object; # MyClass

 $object = MyClass->factory('foo');
 print ref $object; # Subclass::Foo

=head3 C<constructors> defaults:

=over 4

=item * C<view>

C<$VIEW_PUBLIC>.

=item * C<create>

If C<code> is provided, false, otherwise true.

Note that if you supply a C<create> slot, its value will be ignored in favor
of the "default" create value.

=back

=head2 attributes

Each attribute must have a key which specifies the name of the attribute
and point to a hashref containing additional information about the
attribute. An empty hashref will create a simple scalar attribute with the
given name, so a basic getter/setter with no validation is simply:

 attributes => [
    some_attribute => {}
 ]

The values of the hashref should match the values identified in the
C<Class::Meta> "add_attribute" documentation.  C<name> is not required (and
will be ignored if supplied) as name is taken from the hashref key.  C<view>
should be on of the values listed in the C<EXPORT> ":view" section of this
documentation.

The C<type> should be one of the datatypes specified in the C<EXPORT> ":type"
section.  Note that unlike C<Class::Meta>, you do not have to load the type
class.  C<Class::Meta::Declare> will infer the type class from the type you
provide and handle this for you.

The C<authz> and C<create> values should be one of their corresponding values
in the C<EXPORT> section of this document.

The C<context> key indicates whether this is a class or instance attribute.
It's value should be either C<$CTXT_CLASS> or C<$CTXT_OBJECT>.

=head3 C<attributes> defaults:

=over 4

=item * C<name>

Set to the value of the "key" for the attribute:

 rank => { # name will be set to 'rank'
   default => 'private',
 }

=item * C<type>

C<$TYPE_SCALAR>.

=item * C<required>

False.

=item * C<once>

False.

=item * C<label>

None.

=item * C<desc>

None.

=item * C<view>

C<$VIEW_PUBLIC>.

=item * C<authz>

C<$AUTHZ_RDWR>.

=item * C<create>

Value corresponding to value in C<authz> slot.

=item * C<context>

C<$CTXT_OBJECT>.

=item * C<default>

None (Ironic, eh?)

=item * C<override>

False.

=back

=head3 Custom Accessors

If you wish to provide custom attribute accessors, the actual body of the
accessor should be provided with the C<code> key. If this is done, the
C<create> value will automatically be set to C<$CREATE_NONE>. This tells
C<Class::Meta> to not create attribute accessor for you, but to use the code
you have supplied.

There are two ways to create custom attribute code depending on the
accessor style you have chosen.  If you are using regular "perl style"
accessors (the default), then C<code> should point to a code reference or an
anonymous sub:

 password => { # insecure code for demonstration purposes only
   code => sub {
     my $self = shift;
     return $self->{password} unless @_;
     my $password = shift;
     if (length $password < 5) {
       croak "Password too short";
     }
     $self->{password} = $password;
     return $self;
   }
 }

However, if you are using C<$ACC_SEMI_AFFORDANCE> or C<$ACC_AFFORDANCE> style
accessors, then you'll have separate I<get> and I<set> methods.  C<code>
should then point to a hash reference with C<get> and C<set> as the keys and
their values pointing to their corresponding methods.

 meta => [
   accessors => $ACC_SEMI_AFFORDANCE,
 ],
 attributes => [
   password => { # insecure code for demonstration purposes only
     code => {
       get => sub { shift->{password} },
       set => sub {
         my ($self, $password) = @_;
         if (length $password < 5) {
           croak "Password too short";
         }
         $self->{password} = $password;
         return $self;
       }
     }
   }
 ]

For the code above, you may then access the attribute via
C<< $object->password >> and C<< $object->set_password($password) >>.

=head3 Custom Types

You may find the built-in list of types insufficient for your needs.  For
example, you may wish to create an accessor which only accepts types of class
C<Customer>.  In this case, C<Customer> should be a C<Class::Meta> or
C<Class::Meta::Declare> class and should be loaded prior to C<new> being
called.  C<type> should then point to the C<Customer> key.

 Class::Meta::Declare->new(
     meta => [
        key     => 'customer',
        package => 'Customer',
     ],
     @customer_attributes,
     @customer_methods
 );

And later:

 Class::Meta::Declare->new(
     meta => [
         key     => 'some_key',
         package => 'Some::Package',
     ],
     attributes => [
         cust => {
             type => 'customer',
         }
     ]
 );

=head2 methods

Each method must have a key which specifies the name of the method and point
to a hashref containing additional information about the method.  Each hashref
should contain, at minimum, a C<code> key which points to a subref of anonymous
subroutine which defines the method:

 methods => [
   reverse_name => sub {
     my $self = shift;
     return scalar reverse $self->name;
   }
 ]

The values of the hashref should match the values identified in the
C<Class::Meta> "add_method" documentation.  C<name> is not required (and will
be ignored if supplied) as name is taken from the hashref key.  C<view> should
be on of the values listed in the C<EXPORT> ":view" section of this
documentation.

The C<context> key indicates whether this is a class or instance method.  It's
value should be either C<$CTXT_CLASS> or C<$CTXT_OBJECT>.  The default is
C<$CTXT_OBJECT>.

The actual body of the method, if supplied, should be provided with the
C<code> key.  If it's not supplied, it is assumed the the method will still
be available at runtime.  This is if the method is declared elsewhere or will
be provided via C<AUTOLOAD> or similar functionality.

=head3 C<methods> defaults:

=over 4

=item * C<name>

Set to the value of the "key" for the method:

 rank => { # name will be set to 'rank'
   code => \&some_method,
 }

=item * C<label>

None.

=item * C<desc>

None.

=item * C<view>

C<$VIEW_PUBLIC>.

=item * C<context>

C<$CTXT_OBJECT>.

=item * C<caller>

None.

=item * C<args>

None.

=item * C<returns>

None.

=back

=head1 EXPORT

C<Class::Meta::Declare> exports a number of constants on demand.  These
constants are used to provide a simpler interface for C<Class::Meta> use.

See L<CONSTRUCTOR OPTIONS|"CONSTRUCTOR OPTIONS"> for details on where to use
these.

=head2 :acc

Foreach each class, you can specify the type of attribute accessors created.
Defaults to "perl-style" accessors.

See the "Accessors" section for C<Class::Meta>.

See also:

L<Class::Meta::AccessorBuilder|Class::Meta::AccessorBuilder>

L<Class::Meta::AccessorBuilder::Affordance|Class::Meta::AccessorBuilder::Affordance>

L<Class::Meta::AccessorBuilder::SemiAffordance|Class::Meta::AccessorBuilder::SemiAffordance>

=over 4

=item * $ACC_PERL

=item * $ACC_AFFORDANCE

=item * $ACC_SEMI_AFFORDANCE

=back

=head2 :authz

Sets the authorization for each attribute, determining whether people can read
or write to a given accessor.  Defaults to C<Class::Meta::RDWR>.

See L<authz|Class::Meta::Attribute/"authz">.

=over 4

=item * $AUTHZ_READ

=item * $AUTHZ_WRITE

=item * $AUTHZ_RDWR

=item * $AUTHZ_NONE

=back

=head2 :create

Indicates what type of accessor or accessors are to be created for the
attribute.  Generally sets a sensible default based upon the C<authz> setting.

See the "create" section under L<add_attribute|Class::Meta/"add_attribute">.

=over 4

=item * $CREATE_GET

=item * $CREATE_SET

=item * $CREATE_GETSET

=item * $CREATE_NONE

=back

=head2 :ctxt

For each attribute, you may specify if it is a class or instance attribute.

See the "context" section under L<add_attribute|Class::Meta/"add_attribute">.

=over 4

=item * $CTXT_CLASS

=item * $CTXT_OBJECT

=back

=head2 :type

Sets the data type for each attribute. Setting an attribute to an illegal data
type is a fatal error. This list of data types covers all that are supplied
with C<Class::Meta>. If you use others, you'll have to specify them
explicitly.

See L<Data Types|Class::Meta::Attribute/"Data Types">.

=over 4

=item * $TYPE_SCALAR

=item * $TYPE_SCALARREF

=item * $TYPE_ARRAY

=item * $TYPE_ARRAYREF

=item * $TYPE_HASH

=item * $TYPE_HASHREF

=item * $TYPE_CODE

=item * $TYPE_CODEREF

=item * $TYPE_CLOSURE

=item * $TYPE_STRING

=item * $TYPE_BOOLEAN

=item * $TYPE_BOOL

=item * $TYPE_WHOLE

=item * $TYPE_INTEGER

=item * $TYPE_DECIMAL

=item * $TYPE_REAL

=item * $TYPE_FLOAT

=back

=head2 :view

Sets the "visibility" of a constructor, attribute, or method.

See the "view" section under L<add_constructor|Class::Meta/"add_constructor">.

=over 4

=item * $VIEW_PUBLIC

=item * $VIEW_PRIVATE

=item * $VIEW_TRUSTED

=item * $VIEW_PROTECTED

=back

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-meta-declare@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Meta-Declare>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Kineticode, Inc, L<http://www.kineticode.com> for sponsoring this
work.

=head1 SEE ALSO

L<Class::Meta|Class::Meta>

=head1 DEPENDENCIES

L<Class::BuildMethods|Class::BuildMethods>

L<Class::Meta|Class::Meta>

L<Exporter::Tidy|Exporter::Tidy>

L<Readonly|Readonly>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
