# $Id: /local/DBIx-Class-InflateColumn-Currency/Makefile.PL 1540 2008-04-23T01:28:49.429063Z claco  $
use strict;
use warnings;
use inc::Module::Install 0.65;

name 'DBIx-Class-InflateColumn-Currency';
license 'perl';
perl_version '5.008001';
all_from 'lib/DBIx/Class/InflateColumn/Currency.pm';

requires 'DBIx::Class'    => '0.07005'; 
requires 'Data::Currency' => '0.03';

build_requires 'DBD::SQLite'              => '1.11';
build_requires 'Class::Accessor::Grouped' => '0.03';

tests 't/*.t';
clean_files "DBIx-Class-InflateColumn-Currency-* t/var";

eval {
    system 'pod2text lib/DBIx/Class/InflateColumn/Currency.pm > README';
};

auto_install;

WriteMakefile;
