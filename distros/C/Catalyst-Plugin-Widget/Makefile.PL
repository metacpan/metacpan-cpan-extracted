use inc::Module::Install;

name      'Catalyst-Plugin-Widget';
license   'perl';
all_from  'lib/Catalyst/Plugin/Widget.pm';

requires  'Catalyst::Runtime' => 5.80029;

test_requires 'Test::More';

auto_install;

WriteAll;

