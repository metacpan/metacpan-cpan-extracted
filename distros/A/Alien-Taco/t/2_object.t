# Test object module.

use strict;

use Test::More tests => 9;

BEGIN {use_ok('Alien::Taco::Object');}

my $client = new TestClient();


# Check that the object is constructed and destroyed properly.

do {
    my $object = new Alien::Taco::Object($client, 77);

    isa_ok($object, 'Alien::Taco::Object');

    is($object->_number(), 77, 'object number');
};

is($client->{'destroyed'}, 77, 'object destroyed');


# Use a new object to see that it calls client methods correctly.

my $object = new Alien::Taco::Object($client, 56);

$object->call_method('test_method', args => [qw/x y z/]);
is_deeply($client->{'called'},
    [56, 'test_method', 'args', [qw/x y z/]],
    'call method');

is($object->get_attribute('test_attribute'),
   'request 56 attribute test_attribute',
   'get attribute');

$object->set_attribute('test_attribute_set', 'some value');
is_deeply($client->{'set'},
    [56, 'test_attribute_set', 'some value'],
    'set attribute');

my $method = $object->method('test_method_convenience');
isa_ok($method, 'CODE');

$method->('is this convenient?');
is_deeply($client->{'called'},
    [56, 'test_method_convenience', args => ['is this convenient?']],
    'method call convenience');


# Fake Taco client class for the objects under test to interact
# with.

package TestClient;

sub new {
    my $class = shift;

    return bless {
        destroyed => undef,
    }, $class;
}

sub _call_method {
    my $self = shift;
    $self->{'called'} = [@_];
}

sub _destroy_object {
    my $self = shift;
    $self->{'destroyed'} = shift;
}

sub _set_attribute {
    my $self = shift;
    $self->{'set'} = [@_];
}

sub _get_attribute {
    shift; my ($num, $name) = @_;
    return "request $num attribute $name";
}
