# Test client messages.
#
# This test script checks that the client generates Taco messages correctly.

use strict;

use Test::More tests => 12;

BEGIN {use_ok('Alien::Taco');}
BEGIN {use_ok('Alien::Taco::Object');}

my $t = new TestClient();
my $o = new Alien::Taco::Object($t, 42);

$t->call_class_method('SomeClass', 'some_method',
        args => [qw/a b c/], kwargs => {d => 1, e => 2});

is_deeply($t->msg(), {
        action => 'call_class_method',
        class => 'SomeClass',
        name => 'some_method',
        args => [qw/a b c/],
        kwargs => {d => 1, e => 2},
        context => 'void',
    },
    'call_class_method');

my $r = $t->call_function('some_function', args => [qw/x y z/]);

is_deeply($t->msg(), {
        action => 'call_function',
        name => 'some_function',
        args => [qw/x y z/],
        kwargs => undef,
        context => 'scalar',
    },
    'call_function');

my @r = $o->call_method('method_name', kwargs => {i => 1, j => 2});

is_deeply($t->msg(), {
        action => 'call_method',
        number => 42,
        name => 'method_name',
        args => undef,
        kwargs => {i => 1, j => 2},
        context => 'list',
    },
    'call_method');

$t->construct_object('ObjectClass', args => [5,6,7,8]);

is_deeply($t->msg(), {
        action => 'construct_object',
        class => 'ObjectClass',
        args => [5,6,7,8],
        kwargs => undef,
    },
    'construct_object');

undef $o;

is_deeply($t->msg(), {
        action => 'destroy_object',
        number => 42,
    },
    'destroy_object');


$o = new Alien::Taco::Object($t, 88);

$o->get_attribute('att_name');

is_deeply($t->msg(), {
        action => 'get_attribute',
        number => 88,
        name => 'att_name',
    },
    'get_attribute');

$t->get_value('var_name');

is_deeply($t->msg(), {
        action => 'get_value',
        name => 'var_name',
    },
    'get_value');

$t->import_module('Mod::Name', args => [':tag'], kwargs => {x => 7});

is_deeply($t->msg(), {
        action => 'import_module',
        name => 'Mod::Name',
        args => [':tag'],
        kwargs => {x => 7},
    },
    'import_module');

$o->set_attribute('att_name', 999);

is_deeply($t->msg(), {
        action => 'set_attribute',
        number => 88,
        name => 'att_name',
        value => 999,
    },
    'set_attribute');

$t->set_value('var_name', '!');

is_deeply($t->msg(), {
        action => 'set_value',
        name => 'var_name',
        value => '!',
    },
    'set_value');


# A test client which just stores message hashes rather than attempting
# to send them.

package TestClient;

use parent 'Alien::Taco';

sub new {
    my $class = shift;

    return bless {msg => undef}, $class;
}

sub _interact {
    my $self = shift;
    $self->{'msg'} = shift;
}

sub msg {
    my $self = shift;
    return $self->{'msg'};
}
