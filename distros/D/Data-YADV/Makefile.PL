use inc::Module::Install;

name 'Data-YADV';
all_from 'lib/Data/YADV.pm';

requires 'String::CamelCase';
requires 'Try::Tiny';
test_requires 'Test::Spec';

WriteAll;
