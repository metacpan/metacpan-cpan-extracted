use strict;
use inc::Module::Install;

name('Catalyst-Model-Data-Localize');
all_from('lib/Catalyst/Model/Data/Localize.pm');

requires 'Catalyst::Component::InstancePerContext';
requires 'Catalyst::Runtime';
requires 'Data::Localize';
requires 'Class::C3::Adopt::NEXT';

auto_include_deps;
WriteAll;
