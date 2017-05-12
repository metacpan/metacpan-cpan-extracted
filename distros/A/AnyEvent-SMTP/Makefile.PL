use inc::Module::Install;

name     'AnyEvent-SMTP';
all_from 'lib/AnyEvent/SMTP.pm';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';
build_requires 'lib::abs', '0.90';

requires 'Object::Event', '1.0';
requires 'AnyEvent',      '4.82';
requires 'common::sense';

requires 'Sys::Hostname';
requires 'Mail::Address';

auto_install;
auto_provides;

WriteAll;

