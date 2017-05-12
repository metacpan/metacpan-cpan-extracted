use inc::Module::Install 0.67;
use strict;
use warnings;

use 5.006001;

name     'DBIx-Class-InflateColumn-FS';
perl_version '5.006001';
all_from 'lib/DBIx/Class/InflateColumn/FS.pm';

requires 'DBIx::Class'              => 0.08;
requires 'Path::Class'              => 0;
requires 'DBIx::Class::UUIDColumns' => 0.02005;

test_requires 'DBD::SQLite'         => 1.12;
test_requires 'DBICx::TestDatabase' => 0;
test_requires 'File::Find';

eval {
    system 'pod2text lib/DBIx/Class/InflateColumn/FS.pm > README';
};

auto_install;
WriteAll;
