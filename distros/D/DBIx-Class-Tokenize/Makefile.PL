use inc::Module::Install;

name    'DBIx-Class-Tokenize';
all_from    'lib/DBIx/Class/Tokenize.pm';

requires    'DBIx::Class'      => 0;

auto_install;

WriteAll;
