use inc::Module::Install;

name     'DateTime-TimeZone-ICal';
all_from 'lib/DateTime/TimeZone/ICal.pm';
readme_from 'lib/DateTime/TimeZone/ICal.pm';
author   q{Dorian Taylor <dorian@cpan.org>};
license  'apache';

requires 'Moo'                    => '1.006';
requires 'namespace::autoclean'   => '0.20';
requires 'DateTime::TimeZone'     => '1.85';
requires 'DateTime::Set'          => '0.31';
requires 'DateTime::Span'         => '0';
requires 'DateTime::Format::ICal' => '0.09';
requires 'URI'                    => '1.60';

build_requires 'Test::More' => '1.001009';
test_requires  'DateTime'   => '0.70';
test_requires  'Data::ICal' => '0.21';


auto_install;

WriteAll;

