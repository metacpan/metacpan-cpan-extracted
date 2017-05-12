use inc::Module::Install;
name 'Acme-Sneeze-JP';
all_from 'lib/Acme/Sneeze/JP.pm';

requires 'Scalar::Util';
requires 'Exporter::Lite';

build_requires 'Test::More';
auto_include;
WriteAll;
