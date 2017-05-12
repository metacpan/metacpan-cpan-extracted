use inc::Module::Install;

name           'Data-RoundRobin';
all_from       'lib/Data/RoundRobin.pm';
build_requires 'Test::More';

&WriteAll;

