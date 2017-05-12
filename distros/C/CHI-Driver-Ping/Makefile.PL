use inc::Module::Install;

name 'CHI-Driver-Ping';
abstract 'Use MySQL Ping for cache';
all_from 'lib/CHI/Driver/Ping.pm';
author 'Scott Walters <scott@slowass.net>';

perl_version '5.006';

build_requires 'Test::Class' => 0;
build_requires 'Test::Most'  => 0;

requires 'CHI' => '0.241';

license 'perl';

auto_install;

WriteAll;
