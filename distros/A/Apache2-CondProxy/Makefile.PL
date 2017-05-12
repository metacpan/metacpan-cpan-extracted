use inc::Module::Install;

name     'Apache2-CondProxy';
abstract 'This module implements logic for a conditional reverse proxy.';
all_from 'lib/Apache2/CondProxy.pm';
author   q{Dorian Taylor <dorian@cpan.org>};
license  'apache';

requires 'mod_perl2'       => '2.0';
requires 'Path::Class'     => '0.24';
requires 'Apache2::ModSSL' => '0.08';
requires 'URI'             => '1.60';
requires 'URI::Escape'     => '3.31';

build_requires     'Test::More';
configure_requires 'Apache::Test';

clean_files 't/TEST t/SMOKE';

require Apache::TestMM;
Apache::TestMM->import(qw(test clean));

Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

auto_install;

WriteAll;

