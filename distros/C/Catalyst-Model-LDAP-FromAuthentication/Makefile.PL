use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Catalyst-Model-LDAP-FromAuthentication';
all_from 'lib/Catalyst/Model/LDAP/FromAuthentication.pm';

requires 'Moose';
requires 'namespace::autoclean';
requires 'Catalyst::Component::InstancePerContext';
requires 'Catalyst::Model::LDAP' => '0.16';
requires 'Catalyst::Authentication::Store::LDAP' => '0.1004';
requires 'MooseX::Types::Common::String';
requires 'MooseX::Types::LoadableClass' => '0.005';

build_requires 'Catalyst::Runtime';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';

author_tests 't/author';

resources repository => 'git://github.com/bobtfish/catalyst-model-ldap-fromauthentication.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Model/LDAP/FromAuthentication.pm > README")
        and die $!;
}

WriteAll();

