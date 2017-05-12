use strict;
use warnings;
use inc::Module::Install 0.87;

name 'Catalyst-Plugin-Cache-FastMmap';
all_from 'lib/Catalyst/Plugin/Cache/FastMmap.pm';

requires 'Catalyst::Runtime' => '5.7006';
requires 'Cache::FastMmap';
requires 'MRO::Compat';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-Cache-FastMmap/';

WriteAll;
