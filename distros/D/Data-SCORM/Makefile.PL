use inc::Module::Install;

name     'Data-SCORM';
all_from 'lib/Data/SCORM.pm';
author   q{OSFAMERON <osfameron@cpan.org>};
license  'perl';

build_requires 'Test::More';
build_requires 'Test::LongString';

requires 'Any::Moose';
requires 'Mouse';
requires 'MouseX::AttributeHelpers';
requires 'Mouse::Util::TypeConstraints';
requires 'Scalar::Util';
requires 'XML::Twig';
requires 'File::Temp';
requires 'JSON::Any';
requires 'IPC::Run';
requires 'Params::Coerce';

auto_install;

WriteAll;

