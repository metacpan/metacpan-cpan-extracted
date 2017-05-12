use inc::Module::Install;
name 'Algorithm-DimReduction';
all_from 'lib/Algorithm/DimReduction.pm';

requires 'File::Temp';
requires 'File::Copy';
requires 'Storable';
requires 'Class::Accessor::Fast';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
