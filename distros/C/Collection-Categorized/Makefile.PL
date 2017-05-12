use inc::Module::Install;
use strict;
use warnings;

name 'Collection-Categorized';
all_from 'lib/Collection/Categorized.pm';

requires 'Sub::AliasedUnderscore';
requires 'Class::Accessor';

build_requires 'ok';
build_requires 'Test::More';

license 'Perl';

WriteAll;
