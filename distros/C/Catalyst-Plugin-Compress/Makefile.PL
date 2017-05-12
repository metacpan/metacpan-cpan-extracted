use strict;
use warnings;
use inc::Module::Install 0.91;

name 'Catalyst-Plugin-Compress';
all_from 'lib/Catalyst/Plugin/Compress.pm';

requires 'Compress::Zlib';
recommends 'Compress::Bzip2' => 2;
requires 'MRO::Compat';
requires 'Catalyst::Runtime' => '5.80001';
test_requires 'HTTP::Request::Common';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Compress/trunk/';

WriteAll;

