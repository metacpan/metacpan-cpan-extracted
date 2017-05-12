use inc::Module::Install;

name     'AnyEvent-DBD-Pg';
all_from 'lib/AnyEvent/DBD/Pg.pm';
author   q{Mons Anderson <mons@cpan.org>};
license  'perl';

build_requires 'Test::More';
build_requires 'lib::abs';

requires 'common::sense',3;
requires 'AnyEvent',5;
requires 'Scalar::Util';
requires 'DBI';
requires 'DBD::Pg';

auto_provides;

auto_install;

WriteAll;

