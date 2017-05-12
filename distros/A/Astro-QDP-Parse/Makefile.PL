use strict;
use warnings;
use inc::Module::Install;

name 'Astro-QDP-Parse';

license 'gpl3';
all_from 'lib/Astro/QDP/Parse.pm';

build_requires 'Test::More';

requires 'Clone';
requires 'IO::File';
requires 'Regexp::Common';
requires 'Text::Abbrev';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'Params::Validate';

auto_install;

WriteAll;
