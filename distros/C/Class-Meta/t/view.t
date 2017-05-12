#!perl -w

##############################################################################
# Set up the tests.
##############################################################################

use strict;
use Test::More $] < 5.008
  ? (skip_all => 'Older Carp lacks @CARP_NOT support')
  : (tests => 394);
use File::Spec;

##############################################################################
# Create a simple class.
##############################################################################

package Class::Meta::Test;
use strict;

BEGIN {
    Test::More->import;
    use_ok('Class::Meta');
    use_ok('Class::Meta::Types::Numeric');
    use_ok('Class::Meta::Types::String');
}

BEGIN {
    ok( my $c = Class::Meta->new(
        key     => 'person',
        package => __PACKAGE__,
        name    => 'Class::Meta::TestPerson Class',
        trust   => 'Class::Meta::TrustMe',
        desc    => 'Special person class just for testing Class::Meta.',
    ), "Create Class::Meta object" );

    # Add a constructor.
    ok( $c->add_constructor( name => 'new',
                             create  => 1 ),
        "Add new constructor" );

    # Add a protected constructor.
    ok( $c->add_constructor( name    => 'prot_new',
                             view    => Class::Meta::PROTECTED,
                             create  => 1 ),
        "Add protected constructor" );

    # Add a private constructor.
    ok( $c->add_constructor( name    => 'priv_new',
                             view    => Class::Meta::PRIVATE,
                             create  => 1 ),
        "Add private constructor" );

    # Add a trusted constructor.
    ok( $c->add_constructor( name    => 'trust_new',
                             view    => Class::Meta::TRUSTED,
                             create  => 1 ),
        "Add trusted constructor" );

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
# From within the package, the all attributes should just work.
##############################################################################

ok( my $obj = __PACKAGE__->new, "Create new object" );
ok( my $class = __PACKAGE__->my_class, "Get class object" );
is_deeply(
    [map { $_->name } $class->attributes],
    [qw(id name age sn)],
    'Call to attributes() should return all attributes'
);

is_deeply(
    [map { $_->name } $class->constructors],
    [qw(new prot_new priv_new trust_new)],
    'Call to constructors() should return all constructors'
);

# Check id public attribute.
is( $obj->id, 22, 'Check default ID' );
ok( $obj->id(12), "Set ID" );
is( $obj->id, 12, 'Check 12 ID' );
ok( my $attr = $class->attributes('id'), 'Get "id" attribute object' );
is( $attr->get($obj), 12, "Check indirect 12 ID" );
ok( $attr->set($obj, 15), "Indirectly set ID" );
is( $attr->get($obj), 15, "Check indirect 15 ID" );

# Check name protected attribute succeeds.
is( $obj->name, '', 'Check empty name' );
ok( $obj->name('Larry'), "Set name" );
is( $obj->name, 'Larry', 'Check "Larry" name' );
ok( $attr = $class->attributes('name'), 'Get "name" attribute object' );
is( $attr->get($obj), 'Larry', 'Check indirect "Larry" name' );
ok( $attr->set($obj, 'Chip'), "Indirectly set name" );
is( $attr->get($obj), 'Chip', 'Check indirect "chip" name' );

# Check age private attribute succeeds.
is( $obj->age, 0, 'Check default age' );
ok( $obj->age(42), "Set age" );
is( $obj->age, 42, 'Check 42 age' );
ok( $attr = $class->attributes('age'), 'Get "age" attribute object' );
is( $attr->get($obj), 42, "Check indirect 12 age" );
ok( $attr->set($obj, 15), "Indirectly set age" );
is( $attr->get($obj), 15, "Check indirect 15 age" );

# Check sn trusted attribute succeeds.
is( $obj->sn, '', 'Check empty sn' );
ok( $obj->sn('123456789'), "Set sn" );
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

# Make sure that we can set all of the attributes via prot_new().
ok( $obj = __PACKAGE__->prot_new( id   => 10,
                                  name => 'Damian',
                                  sn   => 'au',
                                  age  => 35),
    "Create another prot_new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );
is( $obj->age, 35, 'Check 35 age' )
;is( $obj->sn, 'au', 'Check sn is "au"');

# Do the same with the constructor object.
ok( $ctor = $class->constructors('prot_new'),
    'Get "prot_new" constructor object' );
ok( $obj = $ctor->call(__PACKAGE__,
                       id   => 10,
                       name => 'Damian',
                       sn   => 'au',
                       age  => 35),
    "Create another prot_new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );
is( $obj->age, 35, 'Check 35 age' );
is( $obj->sn, 'au', 'Check sn is "au"');

# Make sure that we can set all of the attributes via priv_new().
ok( $obj = __PACKAGE__->priv_new( id   => 10,
                                  name => 'Damian',
                                  sn   => 'au',
                                  age  => 35),
    "Create another priv_new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );
is( $obj->age, 35, 'Check 35 age' );
is( $obj->sn, 'au', 'Check sn is "au"');

# Do the same with the constructor object.
ok( $ctor = $class->constructors('priv_new'),
    'Get "priv_new" constructor object' );
ok( $obj = $ctor->call(__PACKAGE__,
                       id   => 10,
                       name => 'Damian',
                       sn   => 'au',
                       age  => 35),
    "Create another priv_new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );
is( $obj->age, 35, 'Check 35 age' );
is( $obj->sn, 'au', 'Check sn is "au"');

# Make sure that we can set all of the attributes via trust_new().
ok( $obj = __PACKAGE__->trust_new( id   => 10,
                                  name => 'Damian',
                                  sn   => 'au',
                                  age  => 35),
    "Create another trust_new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );
is( $obj->age, 35, 'Check 35 age' );
is( $obj->sn, 'au', 'Check sn is "au"');

# Do the same with the constructor object.
ok( $ctor = $class->constructors('trust_new'),
    'Get "trust_new" constructor object' );
ok( $obj = $ctor->call(__PACKAGE__,
                       id   => 10,
                       name => 'Damian',
                       sn   => 'au',
                       age  => 35),
    "Create another priv_new object" );

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
is_deeply( [map { $_->name } $class->constructors], [qw(new prot_new)],
           "Call to constructors() should return public and protected ctors" );

# Check id public attribute.
is( $obj->id, 22, 'Check default ID' );
ok( $obj->id(12), "Set ID" );
is( $obj->id, 12, 'Check 12 ID' );
ok( $attr = $class->attributes('id'), 'Get "id" attribute object' );
is( $attr->get($obj), 12, "Check indirect 12 ID" );
ok( $attr->set($obj, 15), "Indirectly set ID" );
is( $attr->get($obj), 15, "Check indirect 15 ID" );

# Check name protected attribute succeeds.
is( $obj->name, '', 'Check empty name' );
ok( $obj->name('Larry'), "Set name" );
is( $obj->name, 'Larry', 'Check Larry name' );
ok( $attr = $class->attributes('name'), 'Get "name" attribute object' );
is( $attr->get($obj), 'Larry', 'Check indirect "Larry" name' );
ok( $attr->set($obj, 'Chip'), "Indirectly set name" );
is( $attr->get($obj), 'Chip', 'Check indirect "chip" name' );

# Check age private attribute
eval { $obj->age(12) };
main::chk( 'private exception',
           qr/age is a private attribute of Class::Meta::Test/);
eval { $obj->age };
main::chk( 'private exception again',
           qr/age is a private attribute of Class::Meta::Test/);

# Check that age fails when accessed indirectly, too.
ok( $attr = $class->attributes('age'), 'Get "age" attribute object' );
eval { $attr->set($obj, 12) };
main::chk('indirect private exception',
          qr/age is a private attribute of Class::Meta::Test/);
eval { $attr->get($obj) };
main::chk('another indirect private exception',
          qr/age is a private attribute of Class::Meta::Test/);

# Check sn trusted attribute fails.
eval { $obj->sn('foo') };
main::chk( 'trusted exception',
           qr/sn is a trusted attribute of Class::Meta::Test/);
eval { $obj->sn };
main::chk( 'trusted exception again',
           qr/sn is a trusted attribute of Class::Meta::Test/);

# Check that sn fails when accessed indirectly, too.
ok( $attr = $class->attributes('sn'), 'Get "sn" attribute object' );
eval { $attr->set($obj, 'foo') };
main::chk('indirect trusted exception',
          qr/sn is a trusted attribute of Class::Meta::Test/);
eval { $attr->get($obj) };
main::chk('another indirect trusted exception',
          qr/sn is a trusted attribute of Class::Meta::Test/);

# Make sure that we can set protected attributes via new().
ok( $obj = __PACKAGE__->new( id   => 10,
                             name => 'Damian'),
    "Create another new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );

# Make sure that the private attribute fails.
$ENV{FOO} = 1;
eval { __PACKAGE__->new( age => 44 ) };
delete $ENV{FOO};
main::chk('constructor private exception',
          qr/age is a private attribute of Class::Meta::Test/);

# Do the same with the new constructor object.
ok( $ctor = $class->constructors('new'), 'Get "new" constructor object' );
ok( $obj = $ctor->call(__PACKAGE__,
                       id   => 10,
                       name => 'Damian'),
    "Create another new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );

# Make sure that the private attribute fails.
eval { $ctor->call(__PACKAGE__, age => 44 ) };
main::chk('indirect constructor private exception',
      qr/age is a private attribute of Class::Meta::Test/);

# Make sure that we can set protected attributes via prot_new().
ok( $obj = __PACKAGE__->prot_new( id   => 10,
                             name => 'Damian'),
    "Create another prot_new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );

# Make sure that the private attribute fails.
eval { __PACKAGE__->prot_new( age => 44 ) };
main::chk('constructor private exception',
      qr/age is a private attribute of Class::Meta::Test/);

# Do the same with the prot_new constructor object.
ok( $ctor = $class->constructors('prot_new'),
    'Get "prot_new" constructor object' );
ok( $obj = $ctor->call(__PACKAGE__,
                       id   => 10,
                       name => 'Damian'),
    "Create another prot_new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->name, 'Damian', 'Check Damian name' );

# Make sure that the private attribute fails.
eval { $ctor->call(__PACKAGE__, age => 44 ) };
main::chk('indirect constructor private exception',
          qr/age is a private attribute of Class::Meta::Test/);

# Make sure that the private constructor fails.
eval { __PACKAGE__->priv_new };
main::chk('priv_new exeption',
          qr/priv_new is a private constructor of Class::Meta::Test/);

# Make sure the same is true of the priv_new constructor object.
ok( $ctor = $class->constructors('priv_new'),
    'Get "priv_new" constructor object' );
eval { $ctor->call(__PACKAGE__) };
main::chk('indirect priv_new exeption',
          qr/priv_new is a private constructor of Class::Meta::Test/);

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
is_deeply(
    [map { $_->name } Class::Meta::Testarama->my_class->attributes],
    [qw(id sn)],
    'Call to attributes() should return public and trusted attrs',
);

is_deeply(
    [map { $_->name } Class::Meta::Testarama->my_class->constructors],
    [qw(new trust_new)],
    'Call to constructors() should return public and trusted ctors',
);

# Check id public attribute.
is( $obj->id, 22, 'Check default ID' );
ok( $obj->id(12), "Set ID" );
is( $obj->id, 12, 'Check 12 ID' );
ok( $attr = $class->attributes('id'), 'Get "id" attribute object' );
is( $attr->get($obj), 12, "Check indirect 12 ID" );
ok( $attr->set($obj, 15), "Indirectly set ID" );
is( $attr->get($obj), 15, "Check indirect 15 ID" );

# Check name protected attribute
eval { $obj->name('foo') };
main::chk('protected exception',
    qr/name is a protected attribute of Class::Meta::Test/);
eval { $obj->name };
main::chk('another protected exception',
    qr/name is a protected attribute of Class::Meta::Test/);

# Check that name fails when accessed indirectly, too.
ok( $attr = $class->attributes('name'), 'Get "name" attribute object' );
eval { $attr->set($obj, 'foo') };
main::chk('indirect protected exception',
    qr/name is a protected attribute of Class::Meta::Test/);
eval { $attr->get($obj) };
main::chk('another indirect protected exception',
    qr/name is a protected attribute of Class::Meta::Test/);

# Check age private attribute
eval { $obj->age(12) };
main::chk( 'private exception',
           qr/age is a private attribute of Class::Meta::Test/);
eval { $obj->age };
main::chk( 'private exception again',
           qr/age is a private attribute of Class::Meta::Test/);

# Check that age fails when accessed indirectly, too.
ok( $attr = $class->attributes('age'), 'Get "age" attribute object' );
eval { $attr->set($obj, 12) };
main::chk('indirect private exception',
          qr/age is a private attribute of Class::Meta::Test/);
eval { $attr->get($obj) };
main::chk('another indirect private exception',
          qr/age is a private attribute of Class::Meta::Test/);

# Check sn trusted attribute succeeds.
is( $obj->sn, '', 'Check empty sn' );
ok( $obj->sn('123456789'), "Set sn" );
is( $obj->sn, '123456789', 'Check "123456789" sn' );
ok( $attr = $class->attributes('sn'), 'Get "sn" attribute object' );
is( $attr->get($obj), '123456789', 'Check indirect "123456789" sn' );
ok( $attr->set($obj, '987654321'), "Indirectly set sn" );
is( $attr->get($obj), '987654321', 'Check indirect "987654321" sn' );

# Make sure that sn trusted attribute works for subclasses, too.
ok( $obj = Class::Meta::Testarama->new, "Create new Testarama object" );
is( $obj->sn, '', 'Check empty sn' );
ok( $obj->sn('123456789'), "Set sn" );
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
main::chk('constructor private exception',
          qr/age is a private attribute of Class::Meta::Test/);

# Make sure that the protected attribute fails.
eval { Class::Meta::Test->new( name => 'Damian' ) };
main::chk('constructor protected exception',
          qr/name is a protected attribute of Class::Meta::Test/);

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
main::chk('indirect constructor private exception',
      qr/age is a private attribute of Class::Meta::Test/);

# Make sure that the protected attribute fails.
eval { $ctor->call('Class::Meta::Test', name => 'Damian' ) };
main::chk('indirect constructor protected exception',
      qr/name is a protected attribute of Class::Meta::Test/);

# Make sure that we can set trusted attributes via trust_new().
ok( $obj = Class::Meta::Test->trust_new( id   => 10,
                                         sn => 'foo'),
    "Create another trust_new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->sn, 'foo', 'Check foo name' );

# Make sure that the private attribute fails.
eval { Class::Meta::Test->trust_new( age => 44 ) };
main::chk('constructor private exception',
      qr/age is a private attribute of Class::Meta::Test/);

# Make sure that the protected attribute fails.
eval { Class::Meta::Test->trust_new( name => 'Damian' ) };
main::chk('constructor protected exception',
      qr/name is a protected attribute of Class::Meta::Test/);

# Do the same with the trust_new constructor object.
ok( $ctor = $class->constructors('trust_new'),
    'Get "trust_new" constructor object' );
ok( $obj = $ctor->call('Class::Meta::Test',
                       id   => 10,
                       sn   => 'foo'),
    "Create another trust_new object" );

is( $obj->id, 10, 'Check 10 ID' );
is( $obj->sn, 'foo', 'Check foo name' );

# Make sure that the private attribute fails.
eval { $ctor->call('Class::Meta::Test', age => 44 ) };
main::chk('indirect constructor private exception',
          qr/age is a private attribute of Class::Meta::Test/);

# Make sure that the private attribute fails.
eval { $ctor->call('Class::Meta::Test', age => 44 ) };
main::chk('indirect constructor private exception',
          qr/age is a private attribute of Class::Meta::Test/);

# Make sure that the protected constructor fails.
eval { Class::Meta::Test->prot_new };
main::chk('prot_new exeption',
          qr/prot_new is a protected constrctor of Class::Meta::Test/);

# Make sure the same is true of the priv_new constructor object.
ok( $ctor = $class->constructors('priv_new'),
    'Get "priv_new" constructor object' );
eval { $ctor->call('Class::Meta::Test') };
main::chk('indirect priv_new exeption',
          qr/priv_new is a private constructor of Class::Meta::Test/);

##############################################################################
# Now do test in a completely independent package.
##############################################################################
package main;

ok( $obj = Class::Meta::Test->new, "Create new object in main" );
ok( $class = Class::Meta::Test->my_class, "Get class object in main" );

# Make sure we can access id.
is( $obj->id, 22, 'Check default ID' );
ok( $obj->id(12), "Set ID" );
is( $obj->id, 12, 'Check 12 ID' );
ok( $attr = $class->attributes('id'), 'Get "id" attribute object' );
is( $attr->get($obj), 12, "Check indirect 12 ID" );
ok( $attr->set($obj, 15), "Indirectly set ID" );
is( $attr->get($obj), 15, "Check indirect 15 ID" );

# Check name protected attribute
eval { $obj->name('foo') };
chk('protected exception',
    qr/name is a protected attribute of Class::Meta::Test/);
eval { $obj->name };
chk('another protected exception',
    qr/name is a protected attribute of Class::Meta::Test/);

# Check that name fails when accessed indirectly, too.
ok( $attr = $class->attributes('name'), 'Get "name" attribute object' );
eval { $attr->set($obj, 'foo') };
chk('indirect protected exception',
    qr/name is a protected attribute of Class::Meta::Test/);
eval { $attr->get($obj) };
chk('another indirect protected exception',
    qr/name is a protected attribute of Class::Meta::Test/);

# Check sn trusted attribute, which can't be accessed by subclasses.
eval { $obj->sn('foo') };
main::chk( 'trusted exception',
           qr/sn is a trusted attribute of Class::Meta::Test/);
eval { $obj->sn };
main::chk( 'trusted exception again',
           qr/sn is a trusted attribute of Class::Meta::Test/);

# Check that sn fails when accessed indirectly, too.
ok( $attr = $class->attributes('sn'), 'Get "sn" attribute object' );
eval { $attr->set($obj, 'foo') };
main::chk('indirect trusted exception',
          qr/sn is a trusted attribute of Class::Meta::Test/);
eval { $attr->get($obj) };
main::chk('another indirect trusted exception',
          qr/sn is a trusted attribute of Class::Meta::Test/);

# Check age private attribute
eval { $obj->age(12) };
chk( 'private exception',
     qr/age is a private attribute of Class::Meta::Test/ );
eval { $obj->age };
chk( 'another private exception',
 qr/age is a private attribute of Class::Meta::Test/);

# Check that age fails when accessed indirectly, too.
ok( $attr = $class->attributes('age'), 'Get "age" attribute object' );
eval { $attr->set($obj, 12) };
chk( 'indirect private exception',
     qr/age is a private attribute of Class::Meta::Test/);
eval { $attr->get($obj) };
chk( 'another indirect private exception',
     qr/age is a private attribute of Class::Meta::Test/);

# Try the constructor with parameters.
ok( $obj = Class::Meta::Test->new( id => 1 ), "Create new object with id" );
is( $obj->id, 1, 'Check 1 ID' );
ok( $ctor = $class->constructors('new'), "Get new constructor" );
ok( $obj = $ctor->call('Class::Meta::Test', id => 52 ),
    "Indirectly create new object with id" );
is( $obj->id, 52, 'Check 52 ID' );

# Make sure that the protected attribute fails.
eval { Class::Meta::Test->new( name => 'foo' ) };
chk( 'constructor protected exception',
     qr/name is a protected attribute of Class::Meta::Test/ );
eval { $ctor->call('Class::Meta::Test', name => 'foo' ) };
chk( 'indirect constructor protected exception',
     qr/name is a protected attribute of Class::Meta::Test/);

# Make sure that the private attribute fails.
eval { Class::Meta::Test->new( age => 44 ) };
chk('constructor private exception',
    qr/age is a private attribute of Class::Meta::Test/);
eval { $ctor->call('Class::Meta::Test', age => 44 ) };
chk( 'indirect constructor private exception',
     qr/age is a private attribute of Class::Meta::Test/);

# Make sure that the protected constructor fails.
eval { Class::Meta::Test->prot_new };
chk( 'prot_new exeption',
     qr/prot_new is a protected constrctor of Class::Meta::Test/ );

# Make sure the same is true of the prot_new constructor object.
ok( $ctor = $class->constructors('prot_new'),
    'Get "prot_new" constructor object' );
eval { $ctor->call(__PACKAGE__) };
chk( 'indirect prot_new exeption',
     qr/prot_new is a protected constrctor of Class::Meta::Test/ );

# Make sure that the private constructor fails.
eval { Class::Meta::Test->priv_new };
chk( 'priv_new exeption',
     qr/priv_new is a private constructor of Class::Meta::Test/ );

# Make sure the same is true of the priv_new constructor object.
ok( $ctor = $class->constructors('priv_new'),
    'Get "priv_new" constructor object' );
eval { $ctor->call(__PACKAGE__) };
chk( 'indirect priv_new exeption',
     qr/priv_new is a private constructor of Class::Meta::Test/ );

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
