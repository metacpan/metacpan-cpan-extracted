use inc::Module::Install 0.91;
use strict;
use warnings;

name 'Catalyst-Authentication-Credential-TypeKey';
all_from 'lib/Catalyst/Authentication/Credential/TypeKey.pm';

requires 'Catalyst::Exception';
requires 'Catalyst::Plugin::Authentication';
requires 'Authen::TypeKey';
requires 'Moose';
requires 'MooseX::Types::Common::String';
requires 'namespace::autoclean';


test_requires 'Catalyst::Runtime';
test_requires 'Test::More';
test_requires 'Test::MockObject';

resources repository => 'git://github.com/zdk/catalyst-authentication-credential-typekey.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Authentication/Credential/TypeKey.pm > README")
        and die;
}

WriteAll();
