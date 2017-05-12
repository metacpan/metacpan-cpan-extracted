use inc::Module::Install;

name 'CHI-Driver-BerkeleyDB';
abstract 'Using BerkeleyDB for cache';
all_from 'lib/CHI/Driver/BerkeleyDB.pm';
author 'Jonathan Swartz <swartz@pobox.com>';

perl_version '5.006';

build_requires 'Test::Class' => 0;
build_requires 'Test::Most'  => 0;

requires 'CHI' => '0.25';
requires 'BerkeleyDB' => '0.30';

license 'perl';

auto_install;

WriteAll;
