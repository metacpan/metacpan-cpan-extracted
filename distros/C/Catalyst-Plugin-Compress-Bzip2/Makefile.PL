use strict;
use warnings;
use inc::Module::Install 0.91;

name 'Catalyst-Plugin-Compress-Bzip2';
all_from 'lib/Catalyst/Plugin/Compress/Bzip2.pm';

requires 'Catalyst::Runtime' => '5.7006';
requires 'Compress::Bzip2' => '2';
requires 'MRO::Compat';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-Compress-Bzip2/';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/Compress/Bzip2.pm > README")
        and die $!;
}

WriteAll;
