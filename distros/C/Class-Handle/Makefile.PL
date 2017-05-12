use strict;
use inc::Module::Install;

name           'Class-Handle';
all_from       'lib/Class/Handle.pm';
requires       'Class::ISA'       => '0.31';
requires       'Class::Inspector' => '1.12';
build_requires 'File::Spec'       => '0.80';
build_requires 'Test::More'       => '0.47';

WriteAll;
