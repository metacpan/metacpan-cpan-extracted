#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More;

eval " use YAML ";
plan skip_all => "YAML is not installed." if $@;
plan 'no_plan';

use MyClass;
my $obj = MyClass->new({ load_plugins => [qw/ AnonMethod /] });
is $obj->call('foo'), 'anonmethod';

MyClass->load_components(qw/ Autocall::InjectMethod /);
my $obj2 = MyClass->new({ load_plugins => [qw/ AnonMethod /] });
is $obj2->call('foo'), 'anonmethod';
@MyClass::ISA = ('Class::Component');

MyClass->load_components(qw/ Autocall::SingletonMethod /);
my $obj3 = MyClass->new({ load_plugins => [qw/ AnonMethod /] });
is $obj3->call('foo'), 'anonmethod';
@MyClass::ISA = ('Class::Component');

MyClass->load_components(qw/ Autocall::Autoload /);
my $obj4 = MyClass->new({ load_plugins => [qw/ AnonMethod /] });
is $obj4->call('foo'), 'anonmethod';
@MyClass::ISA = ('Class::Component');
