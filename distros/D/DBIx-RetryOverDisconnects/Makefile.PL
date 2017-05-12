use inc::Module::Install 0.67;

name     'DBIx-RetryOverDisconnects';
all_from 'lib/DBIx/RetryOverDisconnects.pm';

requires 'DBI'     => 1.44;
requires 'Exception::Class'     => 1.23;

auto_install;
WriteAll;
