use inc::Module::Install;

name     'CatalystX-self';
all_from 'lib/CatalystX/self.pm';
author   'Jason M. Mills <jmmills at cpan.org>';

requires 'self';
requires 'parent';
requires 'Sub::Exporter';

build_requires 'Test::More';

auto_manifest;
auto_install;

WriteAll;

