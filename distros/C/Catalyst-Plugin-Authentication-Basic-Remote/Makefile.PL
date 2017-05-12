use inc::Module::Install;
name 'Catalyst-Plugin-Authentication-Basic-Remote';
all_from 'lib/Catalyst/Plugin/Authentication/Basic/Remote.pm';

build_requires 'Test::More';

requires 'Catalyst' => '5.30';
requires 'LWP::UserAgent';
requires 'MIME::Base64';

use_test_base;
auto_include;
WriteAll;
