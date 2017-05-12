use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-Plugin-SwiffUploaderCookieHack';
all_from 'lib/Catalyst/Plugin/SwiffUploaderCookieHack.pm';

requires 'Moose';
requires 'namespace::autoclean';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';
build_requires 'Catalyst::Plugin::Session::State::Cookie' => '0.17';
build_requires 'Catalyst::Plugin::Session::Store::File' => '0.18';
build_requires 'CGI::Simple::Cookie';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git@github.com:trwww/Catalyst-Plugin-SwiffUploaderCookieHack.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/SwiffUploaderCookieHack.pm > README")
        and die $!;
}

WriteAll();
