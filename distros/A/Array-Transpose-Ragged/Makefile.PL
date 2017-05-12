use inc::Module::Install;

name     'Array-Transpose-Ragged';
all_from 'lib/Array/Transpose/Ragged.pm';
author   q{Kieren Diment <zarquon@cpan.org>};
license  'perl';

requires 'Array::Transpose';
build_requires 'Test::More';

auto_install;

WriteAll;

