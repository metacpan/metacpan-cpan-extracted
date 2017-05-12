use strict;
use warnings;
use inc::Module::Install;

name 'Astro-NED-Query';

all_from 'lib/Astro/NED/Query.pm';

requires 'Class::Accessor::Class'	=> 0.17;
requires 'HTML::Parser';
requires 'HTML::TableParser'	=> 0.32;
requires 'HTML::LinkExtor'	=> 1.31;
requires 'Regexp::Common';
requires 'WWW::Mechanize'	=> 1.22;

build_requires 'Test::More';

auto_install;

WriteAll;
