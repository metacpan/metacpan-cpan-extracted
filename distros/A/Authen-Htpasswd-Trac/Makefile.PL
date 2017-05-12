use inc::Module::Install;
name 'Authen-Htpasswd-Trac';
all_from 'lib/Authen/Htpasswd/Trac.pm';

requires $_ for qw(
    DBI
    DBD::SQLite
    SQL::Abstract
    Authen::Htpasswd
);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
