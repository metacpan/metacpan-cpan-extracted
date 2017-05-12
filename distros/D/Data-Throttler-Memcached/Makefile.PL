use strict;
use inc::Module::Install;

name('Data-Throttler-Memcached');
all_from('lib/Data/Throttler/Memcached.pm');

requires 'Cache::Memcached::Managed';
requires 'Data::Throttler';
requires 'Digest::MD5';

&auto_install;
&WriteAll;