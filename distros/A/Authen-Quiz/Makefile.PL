use inc::Module::Install;

name          'Authen-Quiz';
all_from      'lib/Authen/Quiz.pm';
version_from  'lib/Authen/Quiz.pm';
abstract_from 'lib/Authen/Quiz.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Cache::Memcached'       => 0.66;
requires 'Cache::Memcached::Fast' => 0.66;
requires 'Class::Accessor::Fast'  => 0.31;
requires 'Class::C3'              => 0.66;
requires 'Digest::SHA1'           => 2.11;
requires 'File::Spec'             => 0;
requires 'Jcode'                  => 0.66;
requires 'UNIVERSAL::require'     => 0.66;
requires 'YAML'                   => 0.66;
requires 'YAML::Syck'             => 1.05;

build_requires 'File::Temp';
build_requires 'File::Slurp';
build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
