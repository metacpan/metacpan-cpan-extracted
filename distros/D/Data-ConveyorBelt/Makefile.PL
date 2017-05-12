use inc::Module::Install;
name 'Data-ConveyorBelt';
all_from 'lib/Data/ConveyorBelt.pm';
readme_from 'lib/Data/ConveyorBelt.pm';

requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'List::Util';

test_requires 'Test::More';

use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
