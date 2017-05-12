use inc::Module::Install;

name     'Archive-Zip-Crypt';
all_from 'lib/Archive/Zip/Crypt.pm';
author   q{Matthias Bethke <matthias@towiski.de>};
license  'perl';
requires 'Archive::Zip' => '1.30';

build_requires 'Test::More';

auto_install;

WriteAll;

