use inc::Module::Install;

name 'Catalyst-Authentication-Credential-FBConnect';
all_from 'lib/Catalyst/Authentication/Credential/FBConnect.pm';

requires 'MooseX::Types';
requires 'MooseX::Types::Common';
requires 'namespace::autoclean';
requires 'WWW::Facebook::API';
requires 'Moose';
build_requires 'Catalyst::Runtime';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More';
build_requires 'ok';


WriteAll();
