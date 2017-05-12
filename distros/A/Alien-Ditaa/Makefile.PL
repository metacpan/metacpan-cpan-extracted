use strict;
use warnings;
use inc::Module::Install 0.91;

name 'Alien-Ditaa';
all_from 'lib/Alien/Ditaa.pm';

license 'gpl';

requires 'IPC::Run';
requires 'File::Which';
requires 'Path::Class';
requires 'File::ShareDir';
requires 'Method::Signatures::Simple';
requires 'Moose';
requires 'namespace::autoclean';

test_requires 'Test::More' => '0.88';

prompt_script('script/ditaa');

requires_external_bin 'java';

resources repository => 'git://github.com/bobtfish/Alien-Ditaa.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Alien/Ditaa.pm > README")
        and die $!;
}

WriteAll;

