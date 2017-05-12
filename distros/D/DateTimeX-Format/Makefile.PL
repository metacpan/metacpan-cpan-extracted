use inc::Module::Install;

name     'DateTimeX-Format';
all_from 'lib/DateTimeX/Format.pm';
author   'Evan Carroll <me@evancarroll.com>';
license  'perl';

requires 'Moose';
requires 'MooseX::Types::DateTime::ButMaintained' => '0.13';
requires 'Moose::Role';

requires 'namespace::clean';

requires 'DateTime';
requires 'DateTime::Locale';
requires 'DateTime::TimeZone';
requires 'Carp';

repository 'git://github.com/EvanCarroll/DateTimeX-Format-POSIX-Strptime.git';
homepage 'https://github.com/EvanCarroll/DateTimeX-Format-POSIX-Strptime';

build_requires 'Test::More';

auto_install;

WriteAll;

