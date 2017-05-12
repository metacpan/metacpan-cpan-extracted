use inc::Module::Install;

name     'Collectd-Plugins-Common';
all_from 'lib/Collectd/Plugins/Common.pm';
author   q{Fabien Wernli <cpan@faxm0dem.org>};
license  'perl';

requires 'Collectd';
build_requires 'Test::More';

auto_install;

WriteAll;

