use strict;
use warnings;

use inc::Module::Install;

name 'Cache-Memcached-Fast-Logger';
abstract 'Simple logging (in/out) to Memcached';

author 'Perlover <perlover@perlover.com>';
version_from 'lib/Cache/Memcached/Fast/Logger.pm';
license 'perl';

requires 'Cache::Memcached::Fast';
build_requires 'Test::More';

auto_set_repository;
author_tests('xt');

clean_files 'Cache-Memcached-Fast-Logger-*';

WriteAll();
