use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-Plugin-ConfigLoader-Etc';
all_from 'lib/Catalyst/Plugin/ConfigLoader/Etc.pm';

requires 'Catalyst::Plugin::ConfigLoader';

test_requires 'Data::Dump';

resources repository => 'https://github.com/zdk/catalyst-plugin-configloader-etc';

auto_install;
WriteAll;
