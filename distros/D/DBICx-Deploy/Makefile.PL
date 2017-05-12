use strict;
use warnings;
use inc::Module::Install;

name 'DBICx-Deploy';
all_from 'lib/DBICx/Deploy.pm' ;

requires 'DBIx::Class';
requires 'SQL::Translator';
requires 'Pod::Usage';

build_requires 'Test::More';
build_requires 'DBD::SQLite';

install_script('bin/dbicdeploy');

WriteAll();
