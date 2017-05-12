use inc::Module::Install;
name 'Cache-Memcached-Indexable';
all_from 'lib/Cache/Memcached/Indexable.pm';

build_requires 'Test::More';
requires 'Cache::Memcached'   => 1.17;
requires 'UNIVERSAL::require' => 0.10;
requires 'Digest::SHA1'       => 0;

WriteAll;
