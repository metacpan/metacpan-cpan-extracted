use inc::Module::Install 0.91;

name 'Catalyst-Plugin-Session-PerUser';
all_from 'lib/Catalyst/Plugin/Session/PerUser.pm';

requires 'Moose';
requires 'namespace::autoclean';
requires 'MRO::Compat';
requires 'Catalyst::Plugin::Session' => '0.06';
requires 'Catalyst::Plugin::Authentication';
requires 'Hash::Merge';
requires 'Object::Signature';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-Session-PerUser/';

WriteAll;
