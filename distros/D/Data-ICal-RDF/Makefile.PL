use inc::Module::Install;

name     'Data-ICal-RDF';
all_from 'lib/Data/ICal/RDF.pm';
readme_from 'lib/Data/ICal/RDF.pm';
author   q{Dorian Taylor <dorian@cpan.org>};
license  'apache';

requires 'Moo'                      => '1.006';
requires 'namespace::autoclean'     => '0.20';
requires 'Throwable'                => '0.200008';
requires 'RDF::Trine'               => '1.001';
requires 'DateTime'                 => '0.70';
requires 'DateTime::Format::W3CDTF' => '0.06';
requires 'DateTime::Format::ICal'   => '0.09';
requires 'DateTime::TimeZone::ICal' => '0.01';
requires 'Data::ICal'               => '0.21';
requires 'MIME::Base64'             => '3.13';
requires 'IO::Scalar'               => '2.110';
requires 'Path::Class'              => '0.24';
requires 'UUID::Tiny'               => '1.04';

build_requires 'Test::More';
test_requires  'URI::ni'    => '0.04';

auto_install;

WriteAll;

