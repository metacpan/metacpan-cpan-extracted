use inc::Module::Install 0.65;

name 'Catalyst-Plugin-Authentication-Credential-TypeKey';
all_from 'lib/Catalyst/Plugin/Authentication/Credential/TypeKey.pm';

requires 'Catalyst::Runtime';
requires 'Catalyst::Plugin::Authentication';
requires 'Test::MockObject';
requires 'Authen::TypeKey';

auto_install;
WriteAll;

