use inc::Module::Install;

name     'App-CMAM';
abstract 'Cover-My-Ass-Mode script';
version  '0.02';
author   'Pedro Melo <melo@cpan.org>';
license  'perl';

install_script 'cmam';

requires 'Mac::FSEvents' => 0;

test_requires 'Test::More';

auto_install;

WriteAll;

