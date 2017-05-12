use inc::Module::Install;

name     'Data-Validate-Common';
all_from 'lib/Data/Validate/Common.pm';
author   q{Lenz Gschwendtner <norbu09@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Any::Moose';
requires 'Data::Validate::Domain';

auto_install;

WriteAll;

