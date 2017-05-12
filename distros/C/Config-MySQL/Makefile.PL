use inc::Module::Install;

name     'Config-MySQL';
all_from 'lib/Config/MySQL.pm';
author   q{Iain Arnell <iarnell@gmail.com>};
license  'perl';

build_requires 'Test::More';

requires 'base';
requires 'Config::INI::Reader';
requires 'Config::INI::Writer';

WriteAll;

