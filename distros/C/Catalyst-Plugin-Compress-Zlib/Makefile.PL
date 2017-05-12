use strict;
use warnings;
use inc::Module::Install 0.91;

name 'Catalyst-Plugin-Compress-Zlib';
all_from 'lib/Catalyst/Plugin/Compress/Zlib.pm';

requires 'Catalyst::Runtime' => '5.7006';
requires 'Compress::Zlib';
requires 'MRO::Compat';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-Compress-Zlib/';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/Compress/Zlib.pm > README")
        and die $!;
}

WriteAll;
