use inc::Module::Install;
name 'Acme-JWT';
all_from 'lib/Acme/JWT.pm';

requires 'Crypt::OpenSSL::RSA' => '0.28';
requires 'JSON' => '2.53';
requires 'MIME::Base64' => '3.13';
requires 'Try::Tiny' => '0.09';
requires 'Digest::SHA' => '5.63';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => '0.87_01';
auto_set_repository;
auto_include;
WriteAll;
