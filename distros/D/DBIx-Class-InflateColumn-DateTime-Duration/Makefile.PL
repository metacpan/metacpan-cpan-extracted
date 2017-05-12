use strict;
use warnings;
use inc::Module::Install 0.65;

name 'DBIx-Class-InflateColumn-DateTime-Duration';
license 'perl';
perl_version '5.008001';
all_from 'lib/DBIx/Class/InflateColumn/DateTime/Duration.pm';

requires 'DBIx::Class'                      => '0.07005'; 
requires 'DateTime::Format::Duration::XSD'  => '0.01';
requires 'Try::Tiny'                        => '0.04';

build_requires 'DBD::SQLite'              => '1.11';
build_requires 'Class::Accessor::Grouped' => '0.03';

tests 't/*.t';
clean_files "DBIx-Class-InflateColumn-DateTime-Duration-* t/var";

eval {
        system 'pod2text lib/DBIx/Class/InflateColumn/DateTime/Duration.pm > README';
    };

    auto_install;

    WriteMakefile;

