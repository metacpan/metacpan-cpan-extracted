use strict;
use warnings;
use inc::Module::Install 0.65;

name 'Catalyst-Plugin-Prototype';
all_from 'lib/Catalyst/Plugin/Prototype.pm';

requires 'Catalyst::Runtime' => '5.7006';
requires 'HTML::Prototype'   => '1.48';

auto_install;
WriteAll;
