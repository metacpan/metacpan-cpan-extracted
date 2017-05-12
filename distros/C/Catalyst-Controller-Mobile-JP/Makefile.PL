use inc::Module::Install;

name 'Catalyst-Controller-Mobile-JP';
all_from 'lib/Catalyst/Controller/Mobile/JP.pm';

requires 'Catalyst::Runtime'  => '5.70';
requires 'Class::Accessor::Fast';
requires 'Encode::JP::Mobile' => '0.25';
requires 'Catalyst::Plugin::MobileAgent';
requires 'HTTP::MobileAgent::Plugin::Charset';

build_requires 'Test::More';
build_requires 'HTTP::Request::Common';

use_test_base;
auto_include;

WriteAll;
