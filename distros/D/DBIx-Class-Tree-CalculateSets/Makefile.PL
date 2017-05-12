use inc::Module::Install 0.68;

use strict;
use warnings;

name           'DBIx-Class-Tree-CalculateSets';
license        'MIT';
all_from       'lib/DBIx/Class/Tree/CalculateSets.pm';

requires       'DBIx::Class' => '0.08108';

build_requires 'SQL::Translator' => '0.09007';
build_requires 'Test::More' => '0.47';
build_requires 'Test::Exception' => '0.21';
build_requires 'Test::Pod' => '1.26';

WriteAll;

