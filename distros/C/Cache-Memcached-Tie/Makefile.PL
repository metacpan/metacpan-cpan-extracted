use inc::Module::Install;

name 'Cache-Memcached-Tie';
all_from 'lib/Cache/Memcached/Tie.pm';
requires 'Cache::Memcached::Fast';
license 'perl';
WriteAll();
