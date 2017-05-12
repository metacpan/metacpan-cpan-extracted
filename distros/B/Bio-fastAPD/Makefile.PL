use inc::Module::Install;

name     'Bio-fastAPD';
all_from 'lib/Bio/fastAPD.pm';
license  'perl';
 
build_requires 'Test::More';

auto_install;

WriteAll;

