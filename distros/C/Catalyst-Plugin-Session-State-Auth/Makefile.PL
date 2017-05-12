use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-Plugin-Session-State-Auth';
all_from 'lib/Catalyst/Plugin/Session/State/Auth.pm';

requires 'namespace::clean';
requires 'MRO::Compat';
requires 'Moose';
requires 'MooseX::Emulate::Class::Accessor::Fast';
requires 'Catalyst::Plugin::Session';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';
build_requires 'ok';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git://github.com/zdk/catalyst-plugin-session-state-auth.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/Session/State/Auth.pm > README")
        and die $!;
}

WriteAll();
