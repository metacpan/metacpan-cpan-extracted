use inc::Module::Install;

name     'AnyEvent-Memcached';
author   'Mons Anderson <mons@cpan.org>';
all_from 'lib/AnyEvent/Memcached.pm';
license  'perl';

test_requires 'Test::More';
test_requires 'Test::NoWarnings';
test_requires 'lib::abs', '0.90';
test_requires 'version';

requires 'common::sense',        '2';
requires 'Storable';
requires 'AnyEvent',             '5.0';
requires 'AnyEvent::Connection', '0.05';
requires 'String::CRC32';
#requires 'Devel::Leak::Cb';

#auto_include;
#auto_include_deps;

auto_provides;
auto_install;

WriteAll;

