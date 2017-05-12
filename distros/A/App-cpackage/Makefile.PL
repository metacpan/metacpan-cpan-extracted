use inc::Module::Install;

name     'App-cpackage';
all_from 'lib/App/cpackage.pm';
author   q{Jon Allen (JJ) <jj@jonallen.info>};
license  'perl';

requires 'App::cpanminus' => 1.5002;
requires 'Capture::Tiny';

install_script 'script/cpackage';

build_requires 'Test::More';

WriteAll;

