use inc::Module::Install;

name 'CatalystX-Menu-Tree';
all_from 'lib/CatalystX/Menu/Tree.pm';

test_requires 'Test::More';
no_index 'inc';
requires 'Catalyst::Runtime';
requires 'MRO::Compat';

WriteAll();
