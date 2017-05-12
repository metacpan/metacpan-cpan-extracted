use strict;
use warnings;
use inc::Module::Install;

name 'Cache-Funky-Storage-Memcached';
author 'Tomohiro Teranishi <tomohiro.teranishi@gmail.com>';
all_from 'lib/Cache/Funky/Storage/Memcached.pm';
requires 'Test::More'            => 0;
requires 'Cache::Memcached'      => 0;
requires 'Cache::Funky'          => 0;
requires 'Cache::Funky::Storage' => 0;
requires 'Test::Spelling'        => 0;
license 'perl';
auto_install;
WriteAll;
