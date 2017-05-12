use inc::Module::Install;
name 'Catalyst-Action-Firebug';
all_from 'lib/Catalyst/Action/Firebug.pm';

build_requires 'Test::More';

requires 'Catalyst' => '5.6';
requires 'NEXT';
requires 'MIME::Base64';
requires 'File::Spec';

use_test_base;
auto_include;
WriteAll;
