use strict;
use inc::Module::Install;

name    'Data-Transform-Zlib';
perl_version '5.006';
all_from 'lib/Data/Transform/Zlib.pm';

build_requires 'Test::More' => 0.47;
build_requires 'Data::Transform::Stackable' => 0;
build_requires 'Data::Transform::Line' => 0;

requires 'Carp' => 0;
requires 'Compress::Raw::Zlib' => '2.000';
requires 'Data::Transform' => 0;

auto_provides;

author_tests('t/author');

WriteAll();
