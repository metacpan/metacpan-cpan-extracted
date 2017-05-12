use inc::Module::Install;

name     'AnyEvent-Handle-Writer';
all_from 'lib/AnyEvent/Handle/Writer.pm';
author   q{Mons Anderson <mons@cpan.org>};
license  'perl';

build_requires 'Test::More';
requires 'AnyEvent', 5;
requires 'common::sense', 2;

auto_install;
auto_provides;

WriteAll;

