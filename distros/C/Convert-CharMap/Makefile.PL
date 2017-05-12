#!/usr/bin/perl

use strict;
use inc::Module::Install;

name        'Convert-CharMap';
all_from    'lib/Convert/CharMap.pm';

requires    'charnames';
requires    'XML::Simple';

if ( can_cc() ) {
    requires('YAML::Syck') unless can_use('YAML::XS') or can_use('YAML::Tiny') or can_use('YAML')
} else {
    requires('YAML::Tiny') unless can_use('YAML::XS') or can_use('YAML::Syck') or can_use('YAML::Tiny');
}

auto_provides;

sign; WriteAll;
