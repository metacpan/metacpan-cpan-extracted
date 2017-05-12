use inc::Module::Install;

name     'DBIx-Class-PhoneticSearch';
all_from 'lib/DBIx/Class/PhoneticSearch.pm';
author   'Moritz Onken <onken@netcubed.de>';
license  'perl';

requires 'DBIx::Class' => '0.08103';
requires 'SQL::Translator';
requires 'Text::Phonetic';

build_requires 'Test::More';

repository 'http://github.com/monken/DBIx-Class-PhoneticSearch/tree/master';

auto_install;

WriteAll;

