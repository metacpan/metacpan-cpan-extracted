use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'ASP4x-Linker';
perl_version '5.008001';
license 'perl';
all_from 'lib/ASP4x/Linker.pm';

test_requires 'Test::More'  => '0';
test_requires 'Router::Generic' => '0.016';

requires 'ASP4'             => '1.044';

tests_recursive();
WriteAll();

