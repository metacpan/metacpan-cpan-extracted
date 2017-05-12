use inc::Module::Install 0.65;

name 'Catalyst-Plugin-Authentication-Credential-HTTP';
all_from 'lib/Catalyst/Plugin/Authentication/Credential/HTTP.pm';

requires 'Catalyst::Runtime';
requires 'Catalyst::Plugin::Authentication';
requires 'Data::UUID' => '0.11';
requires 'String::Escape';
requires 'Test::Exception';
requires 'Test::MockObject';
requires 'URI::Escape';

auto_install;
WriteAll;

