
use inc::Module::Install;

name 'Data-Visitor-Encode';
all_from 'lib/Data/Visitor/Encode.pm';

requires 'Encode';
requires 'Data::Visitor', 0.26;
requires 'Scalar::Util';

test_requires 'Test::More';
test_requires 'Test::Exception';

WriteAll;