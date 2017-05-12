use inc::Module::Install;
name 'Acme-DreamyImage';
all_from 'lib/Acme/DreamyImage.pm';

requires
    'self' => 0.32,
    'common::sense' => 0,
    'Imager' => 0.72,
    'Digest::SHA1' => 0,
    'Object::Tiny' => 0;

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

auto_include;
WriteAll;
