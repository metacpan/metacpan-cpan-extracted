use inc::Module::Install;

name('DBIx-Printf');
author('Kazuho Oku');
version_from('lib/DBIx/Printf.pm');
abstract_from('lib/DBIx/Printf.pm');
license('perl');

requires('DBI');
requires('Carp::Clan');

build_requires('DBD::Mock');

auto_include;
auto_install;

WriteAll;
