use inc::Module::Install;
name 'Data-AMF';
all_from 'lib/Data/AMF.pm';

test_requires 'Test::More';
test_requires 'YAML';

requires 'perl' => '5.008001';
requires 'Any::Moose';
requires 'Scalar::Util';
requires 'DateTime';
requires 'XML::LibXML';
requires 'UNIVERSAL::require';

use_test_base;
author_tests 'xt';

auto_include;
auto_set_repository

WriteAll;
