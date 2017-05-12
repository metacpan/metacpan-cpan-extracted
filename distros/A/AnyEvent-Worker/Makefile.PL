use inc::Module::Install;

$^O eq 'MSWin32' and die "Not ready tor MSWin32 yet";

name     'AnyEvent-Worker';
all_from 'lib/AnyEvent/Worker.pm';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'lib::abs', '0.90';
build_requires 'Test::More';
build_requires 'Test::NoWarnings';

requires 'common::sense', 2;
requires 'AnyEvent', 5;
requires 'Storable';

auto_provides;

auto_install;

WriteAll;

