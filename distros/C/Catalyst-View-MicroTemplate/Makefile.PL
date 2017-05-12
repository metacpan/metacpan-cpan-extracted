use strict;
use inc::Module::Install;

name 'Catalyst-View-MicroTemplate';
all_from 'lib/Catalyst/View/MicroTemplate.pm';
requires 'Catalyst';
requires 'Moose';
requires 'Text::MicroTemplate::Extended';
requires 'namespace::clean';

WriteAll;