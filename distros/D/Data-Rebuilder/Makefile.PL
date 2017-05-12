use inc::Module::Install;

name     'Data-Rebuilder';
all_from 'lib/Data/Rebuilder.pm';
author   'lieutar <lieutar@1dk.jp>';

requires 'B';
requires 'Scalar::Util';
requires 'UNIVERSAL';
requires 'Carp';
requires 'Data::Polymorph';
requires 'Sub::Name';
requires 'Lexical::Alias';
requires 'PadWalker';
requires 'B::Deparse';
requires 'Path::Class';
build_requires 'Test::More';
build_requires 'IO::String';

auto_install;

WriteAll;

