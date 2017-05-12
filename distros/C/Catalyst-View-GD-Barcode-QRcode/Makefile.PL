use inc::Module::Install;
name 'Catalyst-View-GD-Barcode-QRcode';
all_from 'lib/Catalyst/View/GD/Barcode/QRcode.pm';

requires 'Catalyst', 5.60;
requires 'GD::Barcode::QRcode', 0.01;
requires 'MRO::Compat';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
