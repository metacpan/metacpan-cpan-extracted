use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'CatalystX-Debug-ResponseHeaders';
all_from 'lib/CatalystX/Debug/ResponseHeaders.pm';

requires 'Moose';
requires 'namespace::autoclean';

build_requires 'Catalyst::Runtime' => '5.80022';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git://git.shadowcat.co.uk/catagits/CatalystX-Debug-ResponseHeaders';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/CatalystX/Debug/ResponseHeaders.pm > README")
        and die $!;
}

WriteAll();
