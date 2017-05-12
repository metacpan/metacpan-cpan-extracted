#!perl -w

##############################################################################
# Set up the tests.
##############################################################################
use strict;
use Test::More $] < 5.008
  ? (skip_all => 'Older Carp lacks @CARP_NOT support')
  : (tests => 208);

BEGIN {
    main::use_ok('Class::Meta');
    main::use_ok('Class::Meta::Types::String');
}

##############################################################################
# Packages we'll use for testing type errors.
package NoAttrBuild;
sub foo {}
$INC{'NoAttrBuild.pm'} = __FILE__;

package NoAttrGet;
sub build {}
$INC{'NoAttrGet.pm'} = __FILE__;

package NoAttrSet;
sub build {}
sub build_attr_get {}
$INC{'NoAttrSet.pm'} = __FILE__;

##############################################################################
# Create some simple classes.
##############################################################################

package Class::Meta::Testing;

BEGIN {
    my $cm = Class::Meta->new;
    $cm->add_constructor( name => 'new' );
    $cm->add_attribute( name => 'tail', type => 'string' );
    $cm->build;
}

package Class::Meta::TestAbstract;
@Class::Meta::TestAbstract::ISA = qw(Class::Meta::Testing);

BEGIN {
    my $cm = Class::Meta->new(abstract => 1);
    $cm->build;
}

package main;

##############################################################################
# Test Class::Meta errors.
eval { Class::Meta->new('foobar') };
chk('odd number to Class::Meta->new',
    qr/Odd number of parameters in call to new()/);

my $cm = Class::Meta->new( package => 'foobar' );
eval { Class::Meta->new( package => 'foobar' ) };

##############################################################################
# Test Class::Meta::Attribute errors.
eval { Class::Meta::Attribute->new };
chk('Attribute->new protected',
    qr/ cannot create Class::Meta::Attribute objects/);

eval { $cm->add_attribute('foo') };
chk('odd number to Class::Meta::Attribute->new',
    qr/Odd number of parameters in call to new()/);

eval { $cm->add_attribute(desc => 'foo') };
chk('Attribute name required',
    qr/Parameter 'name' is required in call to new()/);

eval { $cm->add_attribute(name => 'fo&o') };
chk('Invalid attribute name',
    qr/Attribute 'fo&o' is not a valid attribute name/);

# Create an attribute to use for a few tests. It's private so that there are
# no accessors.
ok( my $attr = $cm->add_attribute( name => 'foo',
                                   type => 'string',
                                   view => Class::Meta::PRIVATE),
    "Create 'foo' attribute");

eval { $cm->add_attribute( name => 'foo') };
chk('Attribute exists', qr/Attribute 'foo' already exists/);

for my $p (qw(view authz create context)) {
    eval { $cm->add_attribute( name => 'hey', $p => 100) };
    chk("Invalid Attribute $p", qr/Not a valid $p parameter: '100'/);
}

eval { $attr->get };
chk('No attribute get method', qr/Cannot get attribute 'foo'/);

eval { $attr->set };
chk('No attribute set method', qr/Cannot set attribute 'foo'/);

eval { $attr->build };
chk('Attribute->build protected',
    qr/ cannot call Class::Meta::Attribute->build/);

##############################################################################
# Test Class::Meta::Class errors.
eval { Class::Meta::Class->new };
chk('Class->new protected',
    qr/ cannot create Class::Meta::Class objects/);

eval { Class::Meta->new( package => 'foobar' ) };
chk('Duplicate class', qr/Class object for class 'foobar' already exists/);

eval { $cm->class->build };
chk('Class->build protected',
    qr/ cannot call Class::Meta::Class->build/);

##############################################################################
# Test Class::Meta::Constructor errors.
my $ctor = $cm->class->constructors('new');
eval { Class::Meta::Constructor->new };
chk('Constructor->new protected',
    qr/ cannot create Class::Meta::Constructor objects/);

eval { $cm->add_constructor('foo') };
chk('odd number to Class::Meta::Constructor->new',
    qr/Odd number of parameters in call to new()/);

eval { $cm->add_constructor(desc => 'foo') };
chk('Constructor name required',
    qr/Parameter 'name' is required in call to new()/);

eval { $cm->add_constructor(name => 'fo&o') };
chk('Invalid constructor name',
    qr/Constructor 'fo&o' is not a valid constructor name/);

# Create an constructor to use for a few tests. It's private so that it
# can't be called from here.
ok( $ctor = $cm->add_constructor( name => 'newer',
                                  view => Class::Meta::PRIVATE),
    "Create 'newer' constructor");

eval { $cm->add_constructor( name => 'newer') };
chk('Constructor exists', qr/Method 'newer' already exists/);

eval { $cm->add_constructor( name => 'hey', view => 100) };
chk("Invalid Constructor view", qr/Not a valid view parameter: '100'/);

eval { $cm->add_constructor( name => 'hey', caller => 100) };
chk("Invalid Constructor caller",
    qr/Parameter caller must be a code reference/);

eval { $ctor->call };
chk('Cannot call constructor', qr/Cannot call constructor 'newer'/);

eval { $ctor->build };
chk('Constructor->build protected',
    qr/ cannot call Class::Meta::Constructor->build/);

# Make sure that the actual constructor's own errors are thrown.
eval { Class::Meta::Testing->new( foo => 1 ) };
chk('Invalid parameter to generated constructor',
    qr/No such attribute 'foo' in Class::Meta::Testing objects/);

##############################################################################
# Test Class::Meta::Method errors.
eval { Class::Meta::Method->new };
chk('Method->new protected',
    qr/ cannot create Class::Meta::Method objects/);

eval { $cm->add_method('foo') };
chk('odd number to Class::Meta::Method->new',
    qr/Odd number of parameters in call to new()/);

eval { $cm->add_method(desc => 'foo') };
chk('Method name required',
    qr/Parameter 'name' is required in call to new()/);

eval { $cm->add_method(name => 'fo&o') };
chk('Invalid method name',
    qr/Method 'fo&o' is not a valid method name/);

# Create an method to use for a few tests. It's private so that it
# can't be called from here.
ok( my $meth = $cm->add_method( name => 'hail',
                                view => Class::Meta::PRIVATE),
    "Create 'hail' method");

eval { $cm->add_method( name => 'hail') };
chk('Method exists', qr/Method 'hail' already exists/);

for my $p (qw(view context)) {
    eval { $cm->add_method( name => 'hey', $p => 100) };
    chk("Invalid Method $p", qr/Not a valid $p parameter: '100'/);
}

eval { $cm->add_method( name => 'hey', caller => 100) };
chk("Invalid Method caller", qr/Parameter caller must be a code reference/);

eval { $meth->call };
chk('Cannot call method', qr/Cannot call method 'hail'/);

##############################################################################
# Test Class::Meta::Type errors.
eval { Class::Meta::Type->new };
chk(' Missing type', qr/Type argument required/);

eval { Class::Meta::Type->new('foo') };
chk('Invalid type', qr/Type 'foo' does not exist/);

eval { Class::Meta::Type->add };
chk('Type key required', qr/Parameter 'key' is required/);

eval { Class::Meta::Type->add( key => 'foo') };
chk('Type name required', qr/Parameter 'name' is required/);

eval { Class::Meta::Type->add( key => 'string', name => 'string' ) };
chk('Type already exists', qr/Type 'string' already defined/);

eval { Class::Meta::Type->add( key => 'foo', name => 'foo', check => {}) };
chk('Invalid type check',
    qr/Paremter 'check' in call to add\(\) must be a code reference/);

eval { Class::Meta::Type->add( key => 'foo', name => 'foo', check => [{}]) };
chk('Invalid type check array',
    qr/Paremter 'check' in call to add\(\) must be a code reference/);

eval {
    Class::Meta::Type->add( key => 'foo',
                            name => 'foo',
                            builder => 'NoAttrBuild');
};
chk('No build', qr/No such function 'NoAttrBuild::build\(\)'/);

eval {
    Class::Meta::Type->add( key => 'foo',
                            name => 'foo',
                            builder => 'NoAttrGet');
};
chk('No attr get', qr/No such function 'NoAttrGet::build_attr_get\(\)'/);

eval {
    Class::Meta::Type->add( key => 'foo',
                            name => 'foo',
                            builder => 'NoAttrSet');
};
chk('No attr set', qr/No such function 'NoAttrSet::build_attr_set\(\)'/);

eval { Class::Meta::Type->build };
chk('Type->build protected', qr/ cannot call Class::Meta::Type->build/);

eval { Class::Meta->default_error_handler('') };
chk('Bad error handler', qr/Error handler must be a code reference/);

# Make sure we get an error for invalid class error handlers.
eval { Class::Meta->new(error_handler => '') };
chk('Class cannot have invalid error handler',
    qr/Error handler must be a code reference/);

my $foo;
Class::Meta->default_error_handler(sub { $foo = shift });

# Some places still use the default, of course.
eval {
    Class::Meta::Type->add( key => 'foo',
                            name => 'foo',
                            builder => 'NoAttrSet');
};
like( $foo, qr/No such function 'NoAttrSet::build_attr_set\(\)'/,
      "New error handler");

# Others muse use the original, since the class object was defined before
# we set up the new default.
eval { $cm->class->build };
chk('Class->build still protected',
    qr/ cannot call Class::Meta::Class->build/);

# Test the abstract attribute.
is( Class::Meta::Testing->my_class->abstract, 0,
    "Testing class isn't abstract" );
is( Class::Meta::TestAbstract->my_class->abstract, 1,
    "TestAbstract class isn't abstract" );

eval { Class::Meta::TestAbstract->new };
chk( 'Cannot create from abstract class',
     qr/^Cannot construct objects of astract class Class::Meta::TestAbstract/);

##############################################################################
# This function handles all the tests.
##############################################################################
sub chk {
    my ($name, $qr) = @_;
    # Catch the exception.
    ok( my $err = $@, "Caught $name error" );
    # Check its message.
    like( $err, $qr, "Correct error" );
    # Make sure it refers to this file.
    like( $err, qr/(?:at\s+\Q$0\E|\Q$0\E\s+at)\s+line/, 'Correct context' );
    # Make sure it doesn't refer to other Class::Meta files.
    unlike( $err, qr|lib/Class/Meta|, 'Not incorrect context')
}
