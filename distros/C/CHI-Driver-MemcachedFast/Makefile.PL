use inc::Module::Install;
name 'CHI-Driver-MemcachedFast';
all_from 'lib/CHI/Driver/MemcachedFast.pm';

perl_version '5.006';

requires 'CHI'    => '0.081';
requires 'CHI::Driver::Memcached'    => 0;
requires 'Cache::Memcached::Fast'    => 0;

build_requires 'Test::Class' => 0;
build_requires 'Test::Deep'  => 0;
build_requires 'Test::More'  => 0;
build_requires 'Test::Builder'  => 0;

license 'perl';

auto_install;

WriteAll;

