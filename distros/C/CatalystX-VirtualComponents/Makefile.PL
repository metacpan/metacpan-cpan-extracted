use inc::Module::Install;

name 'CatalystX-VirtualComponents';
all_from 'lib/CatalystX/VirtualComponents.pm';

requires 'namespace::clean';
requires 'Catalyst::Runtime' => 5.80;
requires 'Devel::InheritNamespace';
requires 'Moose';
requires 'Module::Pluggable::Object';

test_requires 'Test::More';

auto_set_repository;

WriteAll;