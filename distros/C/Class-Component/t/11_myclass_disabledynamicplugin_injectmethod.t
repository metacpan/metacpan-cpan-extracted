#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More qw(no_plan);

use MyClass;
MyClass->load_components(qw/ Autocall::InjectMethod DisableDynamicPlugin /);

my @obj = ();
$obj[0] = MyClass->new;

isa_ok $obj[0], 'MyClass';
isa_ok $obj[0], 'Class::Component';

is $obj[0]->call('default'), 'default';
is $obj[0]->default, 'default';
is $obj[0]->call('hello'), undef;

MyClass->load_plugins(qw/ Hello /);
$obj[1] = MyClass->new;
is $obj[1]->call('default'), 'default';
is $obj[1]->default, 'default';
is $obj[1]->call('hello'), 'hello';
is $obj[1]->hello, 'hello';
is $obj[1]->run_hook('hello')->[0], 'hook hello';

is $obj[1]->call('hello2', 'data'), 'data';
is $obj[1]->hello2('data'), 'data';
is $obj[1]->run_hook('hello2', { value => 'data' })->[0], 'data';
