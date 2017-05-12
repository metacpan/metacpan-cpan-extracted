use inc::Module::Install;
name 'Cache-FastMmap-Tie';
all_from 'lib/Cache/FastMmap/Tie.pm';

requires('Cache::FastMmap');
requires('Best');
requires('Class::Inspector');

build_requires 'Test::More';
build_requires 'YAML';

use_test_base;
auto_include;
auto_install;
WriteAll;
