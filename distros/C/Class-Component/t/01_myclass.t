#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More qw(no_plan);

use MyClass;

my @obj = ();
$obj[0] = MyClass->new;

isa_ok $obj[0], 'MyClass';
isa_ok $obj[0], 'Class::Component';

is $obj[0]->call('default'), 'default';
is $obj[0]->call('hello'), undef;

$obj[1] = MyClass->new({ load_plugins => [qw/ Hello /] });
is $obj[1]->call('default'), 'default';
is $obj[1]->call('hello'), 'hello';
is $obj[1]->run_hook('hello')->[0], 'hook hello';
