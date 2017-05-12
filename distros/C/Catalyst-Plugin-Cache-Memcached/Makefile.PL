use strict;
use warnings;
use inc::Module::Install 0.87;

name 'Catalyst-Plugin-Cache-Memcached';
all_from 'lib/Catalyst/Plugin/Cache/Memcached.pm';

requires 'Catalyst::Runtime' => '5.7006';
requires 'Cache::Memcached';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-Cache-Memcached/';

WriteAll;
