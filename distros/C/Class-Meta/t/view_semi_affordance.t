#!perl -w

##############################################################################
# Set up the tests.
##############################################################################

use strict;
use Test::More tests => 209;

##############################################################################
# Create a simple class.
##############################################################################

package Class::Meta::Test;
use strict;

BEGIN {
    Test::More->import;
    use_ok('Class::Meta');
    use_ok('Class::Meta::Types::Numeric', 'semi-affordance');
    use_ok('Class::Meta::Types::String', 'semi-affordance');
}

BEGIN {
    ok( my $c = Class::Meta->new(
        key     => 'person',
        package => __PACKAGE__,
        trust   => 'Class::Meta::TrustMe',
        name    => 'Class::Meta::TestPerson Class',
        desc    => 'Special person class just for testing Class::Meta.',
    ), "Create Class::Meta object" );

    # Add a constructor.
    ok( $c->add_constructor( name => 'new',
                             create  => 1 ),
        "Add new constructor" );

    # Add a couple of attributes with created methods.
    ok( $c->add_attribute( name     => 'id',
                           view     => Class::Meta::PUBLIC,
                           type     => 'integer',
                           label    => 'ID',
                           required => 1,
                           default  => 22,
                         ),
        "Add id attribute" );
    ok( $c->add_attribute( name     => 'name',
                           view     => Class::Meta::PROTECTED,
                           type     => 'string',
                           label    => 'Name',
                           required => 1,
                           default  => '',
                         ),
        "Add protected name attribute" );
    ok( $c->add_attribute( name     => 'age',
                           view     => Class::Meta::PRIVATE,
                           type     => 'integer',
                           label    => 'Age',
                           desc     => "The person's age.",
                           required => 0,
                           default  => 0,
                         ),
        "Add private age attribute" );
    ok( $c->add_attribute( name     => 'sn',
                           view     => Class::Meta::TRUSTED,
                           type     => 'string',
                           label    => 'SN',
                           desc     => "The person's serial number.",
                           required => 0,
                           default  => '',
                         ),
        "Add trusted sn attribute" );
    $c->build;
}

##############################################################################
# From within the package, the private and public attributes should just work.
##############################################################################

ok( my $obj = __PACKAGE__->new, "Create new object" );
ok( my $class = __PACKAGE__->my_class, "Get class object" );
is_deeply( [map { $_->name } $class->attributes], [qw(id name age sn)],
           'Call to attributes() should return all attributes' );

# Check id public attribute.
is( $obj->id, 22, 'Check default ID' );
ok( $obj->set_id(12), "Set ID" );
is( $obj->id, 12, 'Check 12 ID' );
ok( my $attr = $class->attributes('id'), 'Get "id" attribute object' );
is( $attr->get($obj), 12, "Check indirect 12 ID" );
ok( $attr->set($obj, 15), "Indirectly set ID" );
is( $attr->get($obj), 15, "Check indirect 15 ID" );

# Check name protected attribute succeeds.
is( $obj->name, '', 'Check empty name' );
ok( $obj->set_name('Larry'), "Set name" );
is( $obj->name, 'Larry', 'Check "Larry" name' );
ok( $attr = $class->attributes('name'), 'Get "name" attribute object' );
is( $attr->get($obj), 'Larry', 'Check indirect "Larry" name' );
ok( $attr->set($obj, 'Chip'), "Indirectly set name" );
is( $attr->get($obj), 'Chip', 'Check indirect "chip" name' );

# Check age private attribute succeeds.
is( $obj->age, 0, 'Check default age' );
ok( $obj->set_age(42), "Set age" );
is( $obj->age, 42, 'Check 42 age' );
ok( $attr = $class->attributes('age'), 'Get "age" attribute object' );
is( $attr->get($obj), 42, "Check indirect 12 age" );
ok( $attr->set($obj, 15), "Indirectly set age" );
is( $attr->get($obj), 15, "Check indirect 15 age" );

# Check sn trusted attribute succeeds.
is( $obj->sn, '', 'Check empty sn' );
ok( $obj->set_sn('123456789'), "Set sn" );
is( $obj->sn, '123456789', 'Check "123456789" sn' );
ok( $attr = $class->attributes('sn'), 'Get "sn" attribute object' );
is( $attr->get($obj), '123456789', 'Check indirect "123456789" sn' );
ok( $attr->set($obj, '987654321'), "Indirectly set sn" );
is( $attr->get($obj), '987654321', 'Check indirect "987654321" sn' );

# Make sure that we can set all of the attributes via new().
ok( $obj = __PACKAGE__->new( id   => 10,
                             name => 'Damian',
                             sn   => 'au',
                             age  => 35),
    "Create another new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );
is( $obj->age, 35, 'Check 35 age' );
is( $obj->sn, 'au', 'Check sn is "au"');

# Do the same with the constructor object.
ok( my $ctor = $class->constructors('new'), 'Get "new" constructor object' );
ok( $obj = $ctor->call(__PACKAGE__,
                       id   => 10,
                       name => 'Damian',
                       sn   => 'au',
                       age  => 35),
    "Create another new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );
is( $obj->age, 35, 'Check 35 age' );
is( $obj->sn, 'au', 'Check sn is "au"');

##############################################################################
# Set up an inherited package.
##############################################################################
package Class::Meta::Testarama;
use strict;
use base 'Class::Meta::Test';

BEGIN {
    Test::More->import;
    Class::Meta->new(key => 'testarama')->build;
}

ok( $obj = __PACKAGE__->new, "Create new Testarama object" );
ok( $class = __PACKAGE__->my_class, "Get Testarama class object" );
is_deeply( [map { $_->name } $class->attributes], [qw(id name)],
           "Call to attributes() should return public and protected attrs" );

# Check id public attribute.
is( $obj->id, 22, 'Check default ID' );
ok( $obj->set_id(12), "Set ID" );
is( $obj->id, 12, 'Check 12 ID' );
ok( $attr = $class->attributes('id'), 'Get "id" attribute object' );
is( $attr->get($obj), 12, "Check indirect 12 ID" );
ok( $attr->set($obj, 15), "Indirectly set ID" );
is( $attr->get($obj), 15, "Check indirect 15 ID" );

# Check name protected attribute succeeds.
is( $obj->name, '', 'Check empty name' );
ok( $obj->set_name('Larry'), "Set name" );
is( $obj->name, 'Larry', 'Check Larry name' );
ok( $attr = $class->attributes('name'), 'Get "name" attribute object' );
is( $attr->get($obj), 'Larry', 'Check indirect "Larry" name' );
ok( $attr->set($obj, 'Chip'), "Indirectly set name" );
is( $attr->get($obj), 'Chip', 'Check indirect "chip" name' );

# Check age private attribute
eval { $obj->set_age(12) };
ok( my $err = $@, 'Catch private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct private exception');
eval { $obj->age };
ok( $err = $@, 'Catch another private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct private exception again');

# Check that age fails when accessed indirectly, too.
ok( $attr = $class->attributes('age'), 'Get "age" attribute object' );
eval { $attr->set($obj, 12) };
ok( $err = $@, 'Catch indirect private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct indirectprivate exception');
eval { $attr->get($obj) };
ok( $err = $@, 'Catch another indirect private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct indirect private exception again');

# Check fail sn trusted attribute
eval { $obj->set_sn('foo') };
ok( $err = $@, 'Catch private exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct private exception');
eval { $obj->sn };
ok( $err = $@, 'Catch another private exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct private exception again');

# Check that sn fails when accessed indirectly, too.
ok( $attr = $class->attributes('sn'), 'Get "sn" attribute object' );
eval { $attr->set($obj, 'foo') };
ok( $err = $@, 'Catch indirect private exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct indirectprivate exception');
eval { $attr->get($obj) };
ok( $err = $@, 'Catch another indirect private exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct indirect private exception again');

# Make sure that we can set protected attributes via new().
ok( $obj = __PACKAGE__->new( id   => 10,
                             name => 'Damian'),
    "Create another new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );

# Make sure that the private attribute fails.
eval { __PACKAGE__->new( age => 44 ) };
ok( $err = $@, 'Catch constructor private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct private constructor exception');

# Make sure that the trusted attribute fails.
eval { __PACKAGE__->new( sn => 'foo' ) };
ok( $err = $@, 'Catch constructor trusted exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct trusted constructor exception');

# Do the same with the constructor object.
ok( $ctor = $class->constructors('new'), 'Get "new" constructor object' );
ok( $obj = $ctor->call(__PACKAGE__,
                       id   => 10,
                       name => 'Damian'),
    "Create another new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );

# Make sure that the private attribute fails.
eval { $ctor->call(__PACKAGE__, age => 44 ) };
ok( $err = $@, 'Catch indirect constructor private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct indirect private constructor exception');

# Make sure that the private attribute fails.
eval { $ctor->call(__PACKAGE__, sn => 'foo' ) };
ok( $err = $@, 'Catch indirect constructor trusted exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct indirect trusted constructor exception');

##############################################################################
# Set up a trusted package.
##############################################################################
package Class::Meta::TrustMe;
use strict;

BEGIN { Test::More->import }

ok( $obj = Class::Meta::Test->new, "Create new Test object" );
ok( $class = Class::Meta::Test->my_class, "Get Test class object" );
is_deeply( [map { $_->name } $class->attributes], [qw(id sn)],
           "Call to attributes() should return public and trusted attrs" );
is_deeply( [map { $_->name } Class::Meta::Testarama->my_class->attributes],
           [qw(id sn)],
           "Call to inherited attributes() should also return public and protected attrs" );

# Check id public attribute.
is( $obj->id, 22, 'Check default ID' );
ok( $obj->set_id(12), "Set ID" );
is( $obj->id, 12, 'Check 12 ID' );
ok( $attr = $class->attributes('id'), 'Get "id" attribute object' );
is( $attr->get($obj), 12, "Check indirect 12 ID" );
ok( $attr->set($obj, 15), "Indirectly set ID" );
is( $attr->get($obj), 15, "Check indirect 15 ID" );

# Check name protected attribute
eval { $obj->set_name('foo') };
ok( $err = $@, "Catch protected exception");
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      "Correct protected exception" );
eval { $obj->name };
ok( $err = $@, "Catch another protected exception");
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      "Another correct protected exception" );

# Check that name fails when accessed indirectly, too.
ok( $attr = $class->attributes('name'), 'Get "name" attribute object' );
eval { $attr->set($obj, 'foo') };
ok( $err = $@, "Catch indirect protected exception");
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      "Correct indirect protected exception" );
eval { $attr->get($obj, 'foo') };
ok( $err = $@, "Catch another indirect protected exception");
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      "Another correct indirect protected exception" );

# Check age private attribute
eval { $obj->set_age(12) };
ok( $err = $@, 'Catch private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct private exception');
eval { $obj->age };
ok( $err = $@, 'Catch another private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct private exception again');

# Check that age fails when accessed indirectly, too.
ok( $attr = $class->attributes('age'), 'Get "age" attribute object' );
eval { $attr->set($obj, 12) };
ok( $err = $@, 'Catch indirect private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct indirectprivate exception');
eval { $attr->get($obj) };
ok( $err = $@, 'Catch another indirect private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct indirect private exception again');

# Check sn trusted attribute succeeds.
is( $obj->sn, '', 'Check empty sn' );
ok( $obj->set_sn('123456789'), "Set sn" );
is( $obj->sn, '123456789', 'Check "123456789" sn' );
ok( $attr = $class->attributes('sn'), 'Get "sn" attribute object' );
is( $attr->get($obj), '123456789', 'Check indirect "123456789" sn' );
ok( $attr->set($obj, '987654321'), "Indirectly set sn" );
is( $attr->get($obj), '987654321', 'Check indirect "987654321" sn' );

ok( $obj = Class::Meta::Testarama->new, "Create new Testarama object" );
is( $obj->sn, '', 'Check empty sn' );
ok( $obj->set_sn('123456789'), "Set sn" );
is( $obj->sn, '123456789', 'Check "123456789" sn' );
ok( $attr = $class->attributes('sn'), 'Get "sn" attribute object' );
is( $attr->get($obj), '123456789', 'Check indirect "123456789" sn' );
ok( $attr->set($obj, '987654321'), "Indirectly set sn" );
is( $attr->get($obj), '987654321', 'Check indirect "987654321" sn' );

# Make sure that we can set trusted attributes via new().
ok( $obj = Class::Meta::Test->new( id   => 10,
                                   sn => 'foo'),
    "Create another new object" );
is( $obj->id, 10, 'Check 10 ID' );
is( $obj->sn, 'foo', 'Check foo sn' );

# Make sure that the private attribute fails.
eval { Class::Meta::Test->new( age => 44 ) };
ok( $err = $@, "Catch constructor private exception");
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      "Got the right constructor private exception");

# Make sure that the protected attribute fails.
eval { Class::Meta::Test->new( name => 'Damian' ) };
ok( $err = $@, "Catch constructor protected exception");
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      "Got the right constructor protected exception");

# Do the same with the new constructor object.
ok( $ctor = $class->constructors('new'), 'Get "new" constructor object' );
ok( $obj = $ctor->call('Class::Meta::Test',
                       id   => 10,
                       sn => 'foo'),
    "Create another new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->sn, 'foo', 'Check foo sn' );

# Make sure that the private attribute fails.
eval { $ctor->call('Class::Meta::Test', age => 44 ) };
ok( $err = $@, "Catch indirect constructor private exception");
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      "Got the right indirect constructor private exception");

# Make sure that the protected attribute fails.
eval { $ctor->call('Class::Meta::Test', name => 'Damian' ) };
ok( $err = $@, "Catch indirect constructor protected exception");
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      "Got the right indirect constructor protected exception");

##############################################################################
# Now do test in a completely independent package.
##############################################################################
package main;

ok( $obj = Class::Meta::Test->new, "Create new object in main" );
ok( $class = Class::Meta::Test->my_class, "Get class object in main" );

# Make sure we can access id.
is( $obj->id, 22, 'Check default ID' );
ok( $obj->set_id(12), "Set ID" );
is( $obj->id, 12, 'Check 12 ID' );
ok( $attr = $class->attributes('id'), 'Get "id" attribute object' );
is( $attr->get($obj), 12, "Check indirect 12 ID" );
ok( $attr->set($obj, 15), "Indirectly set ID" );
is( $attr->get($obj), 15, "Check indirect 15 ID" );

# Check name protected attribute
eval { $obj->set_name('foo') };
ok( $err = $@, 'Catch protected exception');
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      'Correct protected exception');
eval { $obj->name };
ok( $err = $@, 'Catch another protected exception');
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      'Correct protected exception again');

# Check that name fails when accessed indirectly, too.
ok( $attr = $class->attributes('name'), 'Get "name" attribute object' );
eval { $attr->set($obj, 'foo') };
ok( $err = $@, 'Catch indirect protected exception');
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      'Correct indirectprotected exception');
eval { $attr->get($obj) };
ok( $err = $@, 'Catch another indirect protected exception');
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      'Correct indirect protected exception again');

# Check age private attribute
eval { $obj->set_age(12) };
ok( $err = $@, 'Catch private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct private exception');
eval { $obj->age };
ok( $err = $@, 'Catch another private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct private exception again');

# Check that age fails when accessed indirectly, too.
ok( $attr = $class->attributes('age'), 'Get "age" attribute object' );
eval { $attr->set($obj, 12) };
ok( $err = $@, 'Catch indirect private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct indirectprivate exception');
eval { $attr->get($obj) };
ok( $err = $@, 'Catch another indirect private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct indirect private exception again');

# Check sn trusted attribute
eval { $obj->set_sn('foo') };
ok( $err = $@, 'Catch private exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct private exception');
eval { $obj->sn };
ok( $err = $@, 'Catch another private exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct private exception again');

# Check that sn fails when accessed indirectly, too.
ok( $attr = $class->attributes('sn'), 'Get "sn" attribute object' );
eval { $attr->set($obj, 'foo') };
ok( $err = $@, 'Catch indirect private exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct indirectprivate exception');
eval { $attr->get($obj) };
ok( $err = $@, 'Catch another indirect private exception');
like( $err, qr/sn is a trusted attribute of Class::Meta::Test/,
      'Correct indirect private exception again');

# Try the constructor with parameters.
ok( $obj = Class::Meta::Test->new( id => 1 ), "Create new object with id" );
is( $obj->id, 1, 'Check 1 ID' );
ok( $ctor = $class->constructors('new'), "Get new constructor" );
ok( $obj = $ctor->call('Class::Meta::Test', id => 52 ),
    "Indirectly create new object with id" );
is( $obj->id, 52, 'Check 52 ID' );

# Make sure that the protected attribute fails.
eval { Class::Meta::Test->new( name => 'foo' ) };
ok( $err = $@, 'Catch constructor protected exception');
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      'Correct protected constructor exception');
eval { $ctor->call('Class::Meta::Test', name => 'foo' ) };
ok( $err = $@, 'Catch indirect constructor protected exception');
like( $err, qr/name is a protected attribute of Class::Meta::Test/,
      'Correct indirect protected constructor exception');

# Make sure that the private attribute fails.
eval { Class::Meta::Test->new( age => 44 ) };
ok( $err = $@, 'Catch constructor private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct private constructor exception');
eval { $ctor->call('Class::Meta::Test', age => 44 ) };
ok( $err = $@, 'Catch indirect constructor private exception');
like( $err, qr/age is a private attribute of Class::Meta::Test/,
      'Correct indirect private constructor exception');

