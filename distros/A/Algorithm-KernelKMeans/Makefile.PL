use inc::Module::Install;

name 'Algorithm-KernelKMeans';
all_from 'lib/Algorithm/KernelKMeans.pm';

requires 'namespace::autoclean'           => '0.11';
requires 'parent'                         => '0.223';
requires 'Carp'                           => '1.16';
requires 'Exporter::Lite'                 => '0.02';
requires 'List::Util'                     => '1.23';
requires 'List::MoreUtils'                => '0.22';
requires 'Moose'                          => '1.1';
requires 'MooseX::Types::Moose'           => '0.23';
requires 'MooseX::Types::Common::Numeric' => '0.001001';
requires 'POSIX'                          => '1.19';
requires 'UNIVERSAL::require'             => '0.13';

tests 't/*.t';
author_tests 'xt';

test_requires 'ExtUtils::testlib' => '6.56';
test_requires 'Test::Exception'   => '0.29';
test_requires 'Test::More'        => '0.88';

auto_set_repository;
auto_include;
WriteAll;
