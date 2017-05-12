use inc::Module::Install;

name     'AnyEvent-SCGI';
all_from 'lib/AnyEvent/SCGI.pm';
author   'Kevin Jones <kevinj@cpan.org>';

build_requires 'Test::More';

requires 'AnyEvent' => '5.2';

recommends 'EV';
recommends 'Coro' => '5.17';

auto_install;

WriteAll;

