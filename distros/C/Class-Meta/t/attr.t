#!/usr/bin/perl -w

##############################################################################
# Set up the tests.
##############################################################################

use strict;
use Test::More tests => 63;
use Carp;

##############################################################################
# Create a simple class.
##############################################################################

package Class::Meta::TestPerson;
use strict;
use Test::More;

# Make sure we can load Class::Meta.
BEGIN {
    use_ok( 'Class::Meta' );
    use_ok( 'Class::Meta::Types::String' );
}

BEGIN {
    # Create a new Class::Meta object.
    ok( my $c = Class::Meta->new(key => 'person'),
        "Create CM object" );
    isa_ok($c, 'Class::Meta');

    # Create an attribute.
    sub inst { bless {} }
    ok my $attr = $c->add_attribute(
        name  => 'inst',
        type  => 'string',
        desc  => 'The inst attribute',
        label => 'inst Attribute',
        create => 'NONE',
        view  => Class::Meta::PUBLIC,
    ), 'Create "inst" attr';
    isa_ok($attr, 'Class::Meta::Attribute');

    # Test its accessors.
    is( $attr->name, "inst", "Check inst name" );
    is( $attr->desc, "The inst attribute", "Check inst desc" );
    is( $attr->label, "inst Attribute", "Check inst label" );
    is( $attr->type, "string", "Check inst type" );
    ok( $attr->view == Class::Meta::PUBLIC, "Check inst view" );

    # Okay, now test to make sure that an attempt to create a attribute
    # directly fails.
    eval { my $attr = Class::Meta::Attribute->new };
    ok( my $err = $@, "Get attribute construction exception");
    like( $err, qr/Package 'Class::Meta::TestPerson' cannot create/,
        "Caught proper exception");

    # Now try it without a name.
    eval{ $c->add_attribute() };
    ok( $err = $@, "Caught no name exception");
    like( $err, qr/Parameter 'name' is required in call to new/,
        "Caught proper no name exception");

    # Try a duplicately-named attribute.
    eval{ $c->add_attribute(name => 'inst') };
    ok( $err = $@, "Caught dupe name exception");
    like( $err, qr/Attribute 'inst' already exists in class/,
        "Caught proper dupe name exception");

    # Try a couple of bogus visibilities.
    eval { $c->add_attribute( name => 'new_attr',
                         view  => 25) };
    ok( $err = $@, "Caught bogus view exception");
    like( $err, qr/Not a valid view parameter: '25'/,
        "Caught proper bogus view exception");
    eval { $c->add_attribute( name => 'new_attr',
                         view  => 10) };
    ok( $err = $@, "Caught another bogus view exception");
    like( $err, qr/Not a valid view parameter: '10'/,
        "Caught another proper bogus view exception");

    # Try a bogus caller.
    eval { $c->add_method( name => 'new_inst',
                         caller => 'foo' ) };
    ok( $err = $@, "Caught bogus caller exception");
    like( $err, qr/Parameter caller must be a code reference/,
        "Caught proper bogus caller exception");

    # Try a bogus type.
    eval { $c->add_attribute(
        name => 'bogus',
        type => 'bogus',
    ) };
    ok( $err = $@, "Caught bogus type exception");
    like( $err, qr/Unknown type: 'bogus'/,
        "Caught proper bogus type exception");

    # Add an attribute with no type.
    eval { $c->add_attribute( name => 'no_type' ) };
    ok( $err = $@, "Caught missing type exception");
    like( $err, qr/No type specified for the 'no_type' attribute/,
        "Caught missing type exception");

    # Now test all of the defaults.
    sub new_attr { 22 }
    ok( $attr = $c->add_attribute(
        name => 'new_attr',
        type => 'scalar',
        create => 'NONE',
    ), "Create 'new_attr'" );
    isa_ok($attr, 'Class::Meta::Attribute');

    # Test its accessors.
    is( $attr->name, "new_attr", "Check new_attr name" );
    ok( ! defined $attr->desc, "Check new_attr desc" );
    ok( ! defined $attr->label, "Check new_attr label" );
    ok( $attr->view == Class::Meta::PUBLIC, "Check new_attr view" );

    ok $c->build, 'Build the class';
}

# Now try subclassing Class::Meta.

package Class::Meta::SubClass;
use base 'Class::Meta';
sub add_attribute {
    Class::Meta::Attribute->new( shift->SUPER::class, @_);
}

package Class::Meta::AnotherTest;
use strict;

BEGIN {
    # Import Test::More functions into this package.
    Test::More->import;

    # Create a new Class::Meta object.
    ok( my $c = Class::Meta::SubClass->new
        (another => __PACKAGE__), "Create subclassed CM object" );
    isa_ok($c, 'Class::Meta');
    isa_ok($c, 'Class::Meta::SubClass');

    sub foo_attr { bless {} }
    ok( my $attr = $c->add_attribute( name => 'foo_attr', type => 'scalar'),
        'Create subclassed foo_attr' );

    isa_ok($attr, 'Class::Meta::Attribute');

    # Test its accessors.
    is( $attr->name, "foo_attr", "Check new foo_attr name" );
    ok( ! defined $attr->desc, "Check new foo_attr desc" );
    ok( ! defined $attr->label, "Check new foo_attr label" );
    ok( $attr->view == Class::Meta::PUBLIC, "Check new foo_attr view" );
}

##############################################################################
# Now try subclassing Class::Meta::Attribute.
package Class::Meta::Attribute::Sub;
use base 'Class::Meta::Attribute';

# Make sure we can override new and build.
sub new { shift->SUPER::new(@_) }
sub build { shift->SUPER::build(@_) }

sub foo { shift->{foo} }

package main;
ok( my $cm = Class::Meta->new(
    attribute_class => 'Class::Meta::Attribute::Sub',
), "Create Class" );
ok( my $attr = $cm->add_attribute(name => 'foo', foo => 'bar', type => 'scalar'),
    "Add foo attribute" );
isa_ok($attr, 'Class::Meta::Attribute::Sub');
isa_ok($attr, 'Class::Meta::Attribute');
is( $attr->name, 'foo', "Check an attibute");
is( $attr->foo, 'bar', "Check added attribute" );

##############################################################################
# Now create a class using strings instead of contants.
STRINGS: {
    package My::Strings;
    use Test::More;
    ok my $cm = Class::Meta->new( key => 'strings' ),
        'Create strings meta object';
    ok $cm->add_attribute(
        name    => 'foo',
        type    => 'string',
        view    => 'PUBLIC',
        authz   => 'RDWR',
        create  => 'GETSET',
        context => 'Object',
    ), 'Add an attribute using strings for constant values';
    ok $cm->build, 'Build the class';
}

ok my $class = My::Strings->my_class, 'Get the class object';
ok $attr = $class->attributes( 'foo' ), 'Get the "foo" attribute';
is $attr->view, Class::Meta::PUBLIC, 'The view should be PUBLIC';
is $attr->authz, Class::Meta::RDWR, 'The authz should be RDWR';
is $attr->context, Class::Meta::OBJECT, 'The context should be OBJECT';

##############################################################################
# Now create a class with a default type.
STRINGS: {
    package My::DefType;
    use Test::More;
    ok my $cm = Class::Meta->new(
        key          => 'def_type',
        default_type => 'integer',
    ), 'Create def_type meta object';
    ok $cm->add_attribute(
        name    => 'foo',
    ), 'Add an attribute with no type';
    ok $cm->build, 'Build the class';
}

ok $class = My::DefType->my_class, 'Get the class object';
ok $attr = $class->attributes( 'foo' ), 'Get the "foo" attribute';
is $attr->type, 'integer', 'Its type should be "integer"';
