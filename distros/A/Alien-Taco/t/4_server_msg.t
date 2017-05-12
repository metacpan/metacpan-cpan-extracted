# Test server messages.
#
# This test script checks that the server handles Taco messages correctly.

use strict;

use Test::More tests => 19;

BEGIN {use_ok('Alien::Taco::Server');}

my $context = 'not set yet';
my (@param, $test_var);
our $variable = 1234;

# Insert the test object manually as we are not using the server's main loop
# which normally calls _replace_objects.
my $o = new TestObject();
my $s = new TestServer();
$s->_replace_objects({o => $o});

is_deeply($s->call_class_method({
        name => 'class_method',
        class => 'TestObject',
        args => undef,
        kwargs => undef,
        context => 'void',
    }),
    {
        action => 'result',
        result => undef,
    },
    'call_class_method');

is($TestObject::context, undef, 'void context');


is_deeply($s->call_function({
        name => 'main::test_func',
        context => 'scalar',
        args => [qw/x y z/],
        kwargs => {e => 'f'},
    }),
    {
        action => 'result',
        result => 4444,
    },
    'call_function');

ok(!$context, 'scalar context');

is_deeply(\@param, [qw/x y z e f/], 'function parameters');


is_deeply($s->call_method({
        number => 1,
        name => 'test_method',
        args => ['AAA'],
        kwargs => {BBB => 'CCC'},
        context => 'map',
    }),
    {
        action => 'result',
        result => {55555 => 666666},
    },
    'call_method (map)');

ok($o->{'context'}, 'map context');

is_deeply($o->{'param'}, [qw/AAA BBB CCC/], 'method paramters');


is_deeply($s->call_method({
        number => 1,
        name => 'test_method',
        args => undef,
        kwargs => undef,
        context => 'list',
    }),
    {
        action => 'result',
        result => [55555, 666666],
    },
    'call_method (list)');

ok($o->{'context'}, 'list context');


my $res = $s->construct_object({
        class => 'TestObject',
        args => undef,
        kwargs => undef,
    });

isa_ok($res->{'result'}, 'TestObject');


is_deeply($s->destroy_object({
        number => 1,
    }),
    {
        action => 'result',
        result => undef,
    },
    'destroy_object');

is($s->_get_object(1), undef, 'object deleted');

# Put it back for further tests.
$s->_replace_objects({o => $o});


is_deeply($s->get_attribute({
        number => 2,
        name => 'k',
    }),
    {
        action => 'result',
        result => 'v',
    },
    'get_attribute');

is_deeply($s->get_value({
        name => '$main::variable',
    }),
    {
        action => 'result',
        result => 1234,
    },
    'get_value');


$INC{'TestModule.pm'} = 't/4_server_msg.t';
$s->import_module({
        name => 'TestModule',
        args => [qw/a b/],
        kwargs => {c => 'd'},
    });
is_deeply(\@TestModule::use_param, [qw/a b c d/], 'import_module');


$s->set_attribute({
        number => 2,
        name => 'k',
        value => 'newval',
    });
is($o->{'k'}, 'newval', 'set_attribute');


$s->set_value({
        name => '$main::variable',
        value => 4321,
    });
is($variable, 4321, 'set_value');


sub test_func {
    $context = wantarray;
    @param = @_;
    return 4444;
}


package TestObject;

$TestObject::context = 'not set yet';

sub new {
    my $class = shift;
    return bless {k => 'v'}, $class;
}

sub test_method {
    my $self = shift;
    $self->{'context'} = wantarray;
    $self->{'param'} = [@_];
    return (55555, 666666);
}

sub class_method {
    my $class = shift;
    $context = wantarray;
    return 7777777;
}


package TestModule;

our @use_param;

sub import {
    my $package = shift;
    @use_param = @_;
}


package TestServer;

use parent 'Alien::Taco::Server';

sub new {
    my $class = shift;
    return bless {
        nobject => 0,
        objects => {},
    }, $class;
}
