use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'CatalystX-Script-FCGI-Engine';
all_from 'lib/CatalystX/Script/FCGI/Engine.pm';

requires 'FCGI::Engine';
requires 'Moose';
requires 'namespace::autoclean';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git://somewhere.com/myproject.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/CatalystX/Script/FCGI/Engine.pm > README")
        and die $!;
}

WriteAll();
