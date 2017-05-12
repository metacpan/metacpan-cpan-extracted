use inc::Module::Install;
name 'Catalyst-Controller-FlashRemoting';
all_from 'lib/Catalyst/Controller/FlashRemoting.pm';

test_requires 'Test::More';
test_requires 'HTTP::Request';

requires 'Catalyst'  => '5.70';
requires 'Data::AMF' => '0.01001';

use_test_base;
auto_include;
WriteAll;
