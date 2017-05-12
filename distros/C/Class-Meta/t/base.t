#!perl -w

##############################################################################
# Set up the tests.
##############################################################################

use strict;
use Test::More tests => 132;

##############################################################################
# Create a simple class.
##############################################################################

package Class::Meta::TestPerson;
use strict;

BEGIN {
    main::use_ok('Class::Meta');
}

BEGIN {
    my $c = Class::Meta->new(
        key     => 'person',
        package => __PACKAGE__,
        name    => 'Class::Meta::TestPerson Class',
        desc    => 'Special person class just for testing Class::Meta.',
    );

    # Add a constructor.
    $c->add_constructor( name => 'new',
                         create  => 1 );

    # Add a couple of attributes with created methods.
    $c->add_attribute( name     => 'id',
                       view     => Class::Meta::PUBLIC,
                       authz    => Class::Meta::READ,
                       create   => Class::Meta::GET,
                       type     => 'integer',
                       label    => 'ID',
                       desc     => "The person object's ID.",
                       required => 1,
                       default  => 12,
                   );
    $c->add_attribute( name     => 'name',
                       view     => Class::Meta::PUBLIC,
                       authz    => Class::Meta::RDWR,
                       create   => Class::Meta::GETSET,
                       type     => 'string',
                       label    => 'Name',
                       desc     => "The person's name.",
                       required => 1,
                       default  => '',
                   );
    $c->add_attribute( name     => 'age',
                       view     => Class::Meta::PUBLIC,
                       authz    => Class::Meta::RDWR,
                       create   => Class::Meta::GETSET,
                       type     => 'integer',
                       label    => 'Age',
                       desc     => "The person's age.",
                       required => 0,
                       default  => undef,
                   );

    # Our custom accessor for goop.
    sub goop { shift->{goop} }

    # Add an attribute for which we will create the accessor method.
    $c->add_attribute( name     => 'goop',
                       view     => Class::Meta::PUBLIC,
                       authz    => Class::Meta::READ,
                       create   => Class::Meta::NONE,
                       type     => 'string',
                       label    => 'Goop',
                       desc     => "The person's gooposity.",
                       required => 0,
                       default  => 'very',
                   );

    # Add a class attribute.
    $c->add_attribute( name     => 'count',
                       type     => 'integer',
                       label    => 'Count',
                       context  => Class::Meta::CLASS,
                       default  => 0,
                   );

    # Add a couple of custom methods.
    $c->add_method( name    => 'chk_pass',
                    view    => Class::Meta::PUBLIC,
                    args    => ['string', 'string'],
                    returns => 'bool',
                );

    $c->add_method( name    => 'shame',
                    view    => Class::Meta::PUBLIC,
                    returns => 'person',
                );

    $c->build;

    my $d = Class::Meta->new(
        key     => 'green_monkey',
        package => 'Class::Meta::GreenMonkey',
        name    => 'Class::Meta::GreenMonkey Class',
        desc    => 'Special monkey class just for testing Class::Meta.',
    );

    # Add a constructor.
    $d->add_constructor( name => 'new',
                         create  => 1 );

    # Add a couple of attributes with created methods.
    $d->add_attribute( name     => 'id',
                       view     => Class::Meta::PUBLIC,
                       authz    => Class::Meta::READ,
                       create   => Class::Meta::GET,
                       type     => 'integer',
                       label    => 'ID',
                       desc     => "The monkey object's ID.",
                       required => 1,
                       default  => 12,
                   );
    $d->build;
}

sub chk_pass {
    my ($self, $un, $pw) = @_;
    return $un eq 'larry' && $pw eq 'yrral' ? 1 : 0;
}

sub shame { shift }

##############################################################################
# Do the tests.
##############################################################################

package main;
# Instantiate a base class object and test its accessors.
ok( my $t = Class::Meta::TestPerson->new, 'Class::Meta::TestPerson->new');
is( $t->id, 12, 'id is 12');
eval { $t->id(1) };

# Test string.
ok( $t->name('David'), 'name to "David"' );
is( $t->name, 'David', 'name is "David"' );
eval { $t->name([]) };
ok( my $err = $@, 'name to array ref croaks' );
like( $err, qr/^Value .* is not a valid string/, 'correct string exception' );

# Grab its metadata object.
ok( my $class = $t->my_class, "Get Class::Meta::Class object" );

# Test the is_a() method.
ok( $class->is_a('Class::Meta::TestPerson'), 'Class is_a TestPerson');

# Test the key methods.
is( $class->key, 'person', 'Key is correct');

# Test the package methods.
is($class->package, 'Class::Meta::TestPerson', 'package()');

# Test the name methods.
is( $class->name, 'Class::Meta::TestPerson Class', "Name is correct");

# Test the description methods.
is( $class->desc, 'Special person class just for testing Class::Meta.',
    "Description is correct");

# Test attributes().
ok(my @attributes = $class->attributes, "Get attributes from attributes()" );
is( scalar @attributes, 5, "Five attributes from attributes()" );
isa_ok($attributes[0], 'Class::Meta::Attribute',
       "First object is a attribute object" );
isa_ok($attributes[1], 'Class::Meta::Attribute',
       "Second object is a attribute object" );
isa_ok($attributes[2], 'Class::Meta::Attribute',
       "Third object is a attribute object" );
isa_ok($attributes[3], 'Class::Meta::Attribute',
       "Fourth object is a attribute object" );
is( $attributes[0]->class, $class, "Check attribute class" );

# Get specific attributes.
ok( @attributes = $class->attributes(qw(age name)), 'Get specific attributes' );
is( scalar @attributes, 2, "Two specific attributes from attributes()" );
isa_ok($attributes[0], 'Class::Meta::Attribute', "Attribute object type" );

is( $attributes[0]->name, 'age', 'First attr name' );
is( $attributes[1]->name, 'name', 'Second attr name' );

# Check the attributes of the "ID" attribute object.
ok( my $p = $class->attributes('id'), "Get ID attribute object" );
is( $p->name, 'id', 'ID name' );
is( $p->desc, "The person object's ID.", 'ID description' );
is( $p->view, Class::Meta::PUBLIC, 'ID view' );
is( $p->authz, Class::Meta::READ, 'ID authorization' );
is( $p->type, 'integer', 'ID type' );
is( $p->label, 'ID', 'ID label' );
ok( $p->required, "ID required" );
is( $p->default, 12, "ID default" );

# Test the attribute accessors.
is( $p->get($t), 12, 'ID is 12' );
# ID is READ, so we shouldn't be able to set it.
eval { $p->set($t, 10) };
ok( $err = $@, "Set val failure" );
like( $err, qr/Cannot set attribute 'id/, 'set val exception' );

# Check the attributes of the "Name" attribute object.
ok( $p = $class->attributes('name'), "Get name attribute" );
is( $p->name, 'name', 'Name name' );
is( $p->desc, "The person's name.", 'Name description' );
is( $p->view, Class::Meta::PUBLIC, 'Name view' );
is( $p->authz, Class::Meta::RDWR, 'Name authorization' );
is( $p->type, 'string', 'Name type' );
is( $p->label, 'Name', 'Name label' );
ok( $p->required, "Name required" );
is( $p->default, '', "Name default" );

# Test the attribute accessors.
is( $p->get($t), 'David', 'Name get' );
ok( $p->set($t, 'Larry'), 'Name set' );
is( $p->get($t), 'Larry', 'New Name get' );
is( $t->name, 'Larry', 'Object name');
ok( $t->name('Damian'), 'Object name' );
is( $p->get($t), 'Damian', 'Final Name get' );

# Check the attributes of the "Age" attribute object.
ok( $p = $class->attributes('age'), "Get age attribute" );
is( $p->name, 'age', 'Age name' );
is( $p->desc, "The person's age.", 'Age description' );
is( $p->view, Class::Meta::PUBLIC, 'Age view' );
is( $p->authz, Class::Meta::RDWR, 'Age authorization' );
is( $p->type, 'integer', 'Age type' );
is( $p->label, 'Age', 'Age label' );
ok( $p->required == 0, "Age required" );
is( $p->default, undef, "Age default" );

# Test the age attribute accessors.
ok( ! defined $p->get($t), 'Age get' );
ok( $p->set($t, 10), 'Age set' );
is( $p->get($t), 10, 'New Age get' );
ok( $t->age == 10, 'Object age');
ok( $t->age(22), 'Object age' );
is( $p->get($t), 22, 'Final Age get' );

# Check the attributes of the "Count" attribute object.
ok( $p = $class->attributes('count'), "Get count attribute" );
is( $p->name, 'count', 'Count name' );
is( $p->desc, undef, 'Count description' );
is( $p->view, Class::Meta::PUBLIC, 'Count view' );
is( $p->authz, Class::Meta::RDWR, 'Count authorization' );
is( $p->type, 'integer', 'Count type' );
is( $p->label, 'Count', 'Count label' );
is( $p->required, 0, "Count required" );
is( $p->default, 0, "Count default" );

# Test the count attribute accessors.
is( $p->get($t), 0, 'Count get' );
ok( $p->set($t, 10), 'Count set' );
is( $p->get($t), 10, 'New Count get' );
is( $t->count, 10, 'Object count');
ok( $t->count(22), 'Set object count' );
is( $p->get($t), 22, 'Final Count get' );

# Make sure they also work as class attributes.
is( Class::Meta::TestPerson->count, 22, 'Class count' );
ok( Class::Meta::TestPerson->count(35), 'Set class count' );
is( Class::Meta::TestPerson->count, 35, 'Class count again' );
is( $t->count, 35, 'Object count after class');
is( $p->get($t), 35, 'Final Count get after class' );

# Test goop attribute accessor.
is( $t->goop, 'very', "Got goop" );
$t->goop('feh');
is( $t->goop, 'very', "Still got goop" );
ok( $p = $class->attributes('goop'), "Get goop attribute object" );
is( $p->get($t), 'very', "Got attribute goop" );
eval { $p->set($t, 'feh') };
ok( $@, "Can't set goop" );
is( $p->get($t), 'very', "Still got attribute goop" );

# Test methods().
ok( my @methods = $class->methods, "Get method objects" );
is( scalar @methods, 2, 'Number of methods from methods()' );
isa_ok($methods[0], 'Class::Meta::Method',
       "First object is a method object" );
isa_ok($methods[1], 'Class::Meta::Method',
       "Second object is a method object" );

# Check the order in which they're returned.
is( $methods[0]->name, 'chk_pass', 'First method' );
is( $methods[1]->name, 'shame', 'Second method' );
is( $methods[0]->class, $class, "Check method class" );
is_deeply( $methods[0]->args, ['string', 'string'], "Check method args" );
is( $methods[0]->returns, 'bool', "Check method returns" );
is( $methods[1]->args, undef, 'Second specific method args' );
is( $methods[1]->returns, 'person', 'Second specific method returns' );

# Get a few specific methods.
ok( @methods = $class->methods(qw(shame chk_pass)),
    'Grab specific methods.');
is( scalar @methods, 2, 'Two methods from methods()' );
is( $methods[0]->name, 'shame', 'First specific method' );
is( $methods[1]->name, 'chk_pass', 'Second specific method' );

# Check out the chk_pass method.
ok( my $m = $class->methods('chk_pass'), "Get chk_pass method object" );
is( $m->name, 'chk_pass', 'chk_pass name' );
ok( $m->call($t, 'larry', 'yrral') == 1, 'Call chk_pass returns true' );
ok( $m->call($t, 'larry', 'foo') == 0, 'Call chk_pass returns false' );

# Test constructors().
ok( my @constructors = $class->constructors, "Get constructor objects" );
is( scalar @constructors, 1, 'Number of constructors from constructors()' );
isa_ok($constructors[0], 'Class::Meta::Constructor',
       "First object is a constructor object" );

# Check the order in which they're returned.
is( $constructors[0]->name, 'new', 'Check new constructor name' );
is( $constructors[0]->class, $class, "Check constructor class" );

# Get a few specific constructors.
ok( @constructors = $class->constructors(qw(new)),
    'Grab specific constructor.');
is( scalar @constructors, 1, 'Two constructors from constructors()' );
is( $constructors[0]->name, 'new', 'Check specific constructor' );

# Try getting the class object via the for_key() class method.
is( Class::Meta->for_key($class->key), $class, "for_key returns class" );

# Try getting a list of all class object keys
can_ok( 'Class::Meta', 'keys' );
ok( my $keys = Class::Meta->keys, 'Calling keys in scalar context should succeed');
is( ref $keys, 'ARRAY', 'And it should return an array ref');
@$keys = sort @$keys;
is_deeply($keys, [qw/green_monkey person/], 'And keys should return the correct keys');

ok( my @keys = Class::Meta->keys, 'Calling keys in list context should succeed');
is(scalar @keys, 2, 'And it should return the correct number of keys');
@keys = sort @keys;
is_deeply(\@keys, [qw/green_monkey person/], 'And keys should return the correct keys');

# try deleting the class object classes
can_ok('Class::Meta', 'clear');
Class::Meta->clear('green_monkey');
@keys = Class::Meta->keys;
is_deeply(\@keys, ['person'], 'And it should delete a key if provided with one');

Class::Meta->clear('no_such_key');
@keys = Class::Meta->keys;
is_deeply(\@keys, ['person'], 'But deleting a non-existent key should be a no-op');

Class::Meta->clear;
@keys = Class::Meta->keys;
is_deeply(\@keys, [], 'And calling it without arguments should remove all keys');
__END__
