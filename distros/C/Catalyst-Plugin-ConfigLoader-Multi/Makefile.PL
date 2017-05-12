use strict;
use warnings;
use inc::Module::Install;

name 'Catalyst-Plugin-ConfigLoader-Multi';
author 'Mashiro Funakoshi <masap@cpan.org>';
all_from 'lib/Catalyst/Plugin/ConfigLoader/Multi.pm';
requires 'Test::More'                     => 0;
requires 'Catalyst'                       => 0;
requires 'Catalyst::Plugin::ConfigLoader' => 0.17;
requires 'Test::Spelling'                 => 0;
license 'perl';
auto_install;
WriteAll;
