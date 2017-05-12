use strict;
use warnings;
use inc::Module::Install;

perl_version '5.008004';

name 'DBIx-Class-Bootstrap-Simple';
all_from 'lib/DBIx/Class/Bootstrap/Simple.pm';
license 'perl';

requires 'DBIx::Class';

WriteAll();
