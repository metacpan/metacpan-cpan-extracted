use inc::Module::Install;

all_from       'lib/AnyEvent/Plurk.pm';
requires_from  'lib/AnyEvent/Plurk.pm';
readme_from    'lib/AnyEvent/Plurk.pm';

requires       'Object::Event' => '1.21';

build_requires 'Test::More' => "0.88";

license        'mit';
repository     'http://github.com/gugod/AnyEvent-Plurk';

auto_include_deps;
auto_install;

tests          't/*.t';

WriteAll;
