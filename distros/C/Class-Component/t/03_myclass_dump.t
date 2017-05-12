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

my $dump_file = "$FindBin::Bin/03_myclass_dump.dump";

if (1) {

my $obj = YAML::LoadFile($dump_file);
my @obj = @{ $obj };

isa_ok $obj[0], 'MyClass';
isa_ok $obj[0], 'Class::Component';

is $obj[0]->call('default'), 'default';

is $obj[1]->call('default'), 'default';
is $obj[1]->call('hello'), 'hello';
is $obj[1]->run_hook('hello')->[0], 'hook hello';

} else {

my @obj = ();
$obj[0] = MyClass->new;
$obj[1] = MyClass->new({ load_plugins => [qw/ Hello /] });
YAML::DumpFile($dump_file, \@obj);

}
