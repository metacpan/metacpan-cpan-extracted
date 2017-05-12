#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More qw(no_plan);

use MyClass;
MyClass->load_components(qw/ Autocall::Autoload /);

my @obj = ();
$obj[0] = MyClass->new;

isa_ok $obj[0], 'MyClass';
isa_ok $obj[0], 'Class::Component';

is $obj[0]->call('default'), 'default';
is $obj[0]->default, 'default';
is $obj[0]->call('hello'), undef;

$obj[1] = MyClass->new({ load_plugins => [qw/ Hello /] });
is $obj[1]->call('default'), 'default';
is $obj[1]->default, 'default';
is $obj[1]->call('hello'), 'hello';
is $obj[1]->hello, 'hello';
is $obj[1]->run_hook('hello')->[0], 'hook hello';

$obj[0]->remove_method( default => 'MyClass::Plugin::Default' );
is $obj[0]->call('default'), undef;
eval { $obj[0]->default };
isnt $@, undef;

$obj[1]->remove_hook( hello => { plugin => 'MyClass::Plugin::Hello', method => 'hello_hook' } );
is $obj[1]->run_hook('hello'), undef;
