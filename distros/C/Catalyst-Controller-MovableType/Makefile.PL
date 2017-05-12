use strict;
use warnings;
use if $Module::Install::AUTHOR, 'Module::Install::AuthorRequires';
use inc::Module::Install 0.91;
use Module::Install::AuthorTests;

name 'Catalyst-Controller-MovableType';
all_from 'lib/Catalyst/Controller/MovableType.pm';

requires 'Moose';
requires 'namespace::autoclean';
requires 'Catalyst::Controller::WrapCGI';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'ssh://catagits@git.shadowcat.co.uk/Catalyst-Controller-MovableType.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Controller/MovableType.pm > README")
        and die $!;
}

WriteAll();
