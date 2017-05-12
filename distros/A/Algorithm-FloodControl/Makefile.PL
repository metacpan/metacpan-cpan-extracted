use inc::Module::Install;

name     'Algorithm-FloodControl';
all_from 'lib/Algorithm/FloodControl.pm';
author   'Andrey Kostenko <andrey@kostenko.name>';

build_requires 'Test::More';
test_requires 'Cache::FastMmap';
test_requires 'File::Temp';
requires 'Module::Install' => '0.77';
requires 'Module::Load';
requires 'Params::Validate';
requires 'Class::Accessor::Fast';
requires 'version';

auto_install;

WriteAll;

