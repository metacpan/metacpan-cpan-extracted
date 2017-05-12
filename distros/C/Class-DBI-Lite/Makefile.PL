use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'Class-DBI-Lite';
perl_version '5.008001';
license 'perl';
all_from 'lib/Class/DBI/Lite.pm';

test_requires 'Test::More'          => '0.77';

test_requires 'Test::Memory::Cycle' => 0;
test_requires 'DBD::SQLite'         => 0;

requires 'DBI'                      => 0;
requires 'Ima::DBI::Contextual'     => 1.005;
#requires 'DBIx::ContextualFetch'    => 0;
requires 'SQL::Abstract'            => 0;
requires 'SQL::Abstract::Limit'     => 0;
recommends  'Cache::Memcached'      => 1.27;

tests_recursive();
WriteAll();

