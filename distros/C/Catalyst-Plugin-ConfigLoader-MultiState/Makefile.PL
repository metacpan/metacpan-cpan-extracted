use inc::Module::Install 0.77;

name     'Catalyst-Plugin-ConfigLoader-MultiState';
all_from 'lib/Catalyst/Plugin/ConfigLoader/MultiState.pm';

requires 'File::Spec'        => 3.29;
requires 'Catalyst::Runtime' => '5.71';
requires 'Class::Accessor::Grouped';
requires 'MRO::Compat';
requires 'parent';

test_requires 'Test::More';

auto_install;
WriteAll;
