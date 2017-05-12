use strict;
use warnings;
use inc::Module::Install 1.06;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'CatalystX-Script-Server-Starman';
all_from 'lib/CatalystX/Script/Server/Starman.pm';

requires 'Moose';
requires 'namespace::autoclean';

requires 'Catalyst::Runtime' => '5.89';
requires 'Starman';

build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git://git.shadowcat.co.uk/catagits/CatalystX-Script-Server-Starman.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/CatalystX/Script/Server/Starman.pm > README")
        and die $!;
}

WriteAll();
