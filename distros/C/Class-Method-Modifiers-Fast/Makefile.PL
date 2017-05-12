use inc::Module::Install;
name 'Class-Method-Modifiers-Fast';
all_from 'lib/Class/Method/Modifiers/Fast.pm';

requires       'Data::Util' => 0.55;

test_requires 'Test::More';
test_requires 'Test::Exception';

use_test_base;
auto_include;
WriteAll;
