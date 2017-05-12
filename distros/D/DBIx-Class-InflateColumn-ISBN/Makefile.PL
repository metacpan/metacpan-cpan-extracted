use strict;
use warnings;
use inc::Module::Install 0.65;

name 'DBIx-Class-InflateColumn-ISBN';
license 'perl';
perl_version '5.006001';
all_from 'lib/DBIx/Class/InflateColumn/ISBN.pm';

requires 'DBIx::Class' => 0.07005;
requires 'Business::ISBN' => 1.82;

tests 't/*.t';
clean_files 'DBIx-Class-InflateColumn-ISBN-* Makefile inc META.yml';

eval {
    system 'pod2text lib/DBIx/Class/InflateColumn/ISBN.pm > README';
};

auto_install;
WriteAll;
