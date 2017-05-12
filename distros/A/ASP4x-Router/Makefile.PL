use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'ASP4x-Router';
perl_version '5.008001';
license 'perl';
all_from 'lib/ASP4x/Router.pm';

test_requires 'Test::More'  => '0';

requires 'ASP4'             => '1.080';
requires 'Router::Generic'  => '0.016';
recommends 'Apache2::RequestRec';

tests_recursive();
WriteAll();

