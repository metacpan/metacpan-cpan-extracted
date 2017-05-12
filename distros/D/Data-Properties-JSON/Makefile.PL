use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'Data-Properties-JSON';
perl_version '5.008001';
license 'perl';
all_from 'lib/Data/Properties/JSON.pm';

test_requires 'Test::More'  => '0';

requires  'JSON::XS';

tests_recursive();
WriteAll();

