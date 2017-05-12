use inc::Module::Install;

name     'Barcode-Code93';
all_from 'lib/Barcode/Code93.pm';
author   q{Mark A. Stratman <stratman@gmail.com>};
license  'perl';

requires 'Moo';

build_requires 'Test::More';

resources repository => 'https://github.com/mstratman/Barcode-Code93';

auto_install;

WriteAll;

