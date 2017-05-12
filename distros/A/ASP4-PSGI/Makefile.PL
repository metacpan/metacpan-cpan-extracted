use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'ASP4-PSGI';
perl_version '5.008001';
license 'perl';
all_from 'lib/ASP4/PSGI.pm';

test_requires 'Test::More'  => '0';

requires 'ASP4'   => '1.077';
requires 'PSGI'   => '1.03';
requires 'Plack'  => '0.9949';

tests_recursive();
WriteAll();

