use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Acme-CatalystX-ILoveDebug';
all_from 'lib/Acme/CatalystX/ILoveDebug.pm';

requires 'Moose';
requires 'namespace::autoclean';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'http://goatse.co.uk/~bobtfish/Acme-Catalyst-ILoveDebug.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Acme/CatalystX/ILoveDebug.pm > README")
        and die $!;
}

WriteAll();
