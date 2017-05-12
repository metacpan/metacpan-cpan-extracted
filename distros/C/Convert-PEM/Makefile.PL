use inc::Module::Install;
name 'Convert-PEM';
all_from 'lib/Convert/PEM.pm';
readme_from 'lib/Convert/PEM.pm';

requires 'Class::ErrorHandler';
requires 'MIME::Base64';
requires 'Convert::ASN1' => '0.10';
requires 'Digest::MD5';
requires 'Crypt::DES_EDE3';

test_requires 'Test::More';
test_requires 'Test::Exception';

use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
