use inc::Module::Install 0.87;

name 'Catalyst-Plugin-Session-DynamicExpiry';
all_from 'lib/Catalyst/Plugin/Session/DynamicExpiry.pm';

requires 'Catalyst::Runtime' => '5.80';
requires 'Moose';
requires 'namespace::autoclean';
requires 'MRO::Compat';
requires 'Try::Tiny';
requires 'Catalyst::Plugin::Session' => '0.11';

requires 'Test::More';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-Session-DynamicExpiry/';

WriteAll;
