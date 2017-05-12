#!perl

use strict;
use warnings;
use lib 't';

use FindBin;
use Test::More;

use MyClass;
MyClass->class_component_reinitialize( reload_plugin => 1 );

eval " use YAML ";
plan skip_all => "YAML is not installed." if $@;
plan 'no_plan';

my $dump_file = "$FindBin::Bin/04_myclass_autoload_dump.dump";

if (1) {

my $obj = YAML::LoadFile($dump_file);
my @obj = @{ $obj };

isa_ok $obj[0], 'MyClass';
isa_ok $obj[0], 'Class::Component';

is $obj[0]->call('default'), 'default';
is $obj[0]->default, 'default';

is $obj[1]->call('default'), 'default';
is $obj[1]->default, 'default';
is $obj[1]->call('hello'), 'hello';
is $obj[1]->hello, 'hello';
is $obj[1]->run_hook('hello')->[0], 'hook hello';

is $obj[1]->call('hello2', 'data'), 'data';
is $obj[1]->hello2('data'), 'data';
is $obj[1]->run_hook('hello2', { value => 'data' })->[0], 'data';

} else {

MyClass->load_components(qw/ Autocall /);
my @obj = ();
$obj[0] = MyClass->new;
$obj[1] = MyClass->new({ load_plugins => [qw/ Hello /] });
YAML::DumpFile($dump_file, \@obj);

}
