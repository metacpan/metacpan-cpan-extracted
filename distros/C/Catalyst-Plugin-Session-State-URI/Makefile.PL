use inc::Module::Install 0.87;

name 'Catalyst-Plugin-Session-State-URI';
all_from 'lib/Catalyst/Plugin/Session/State/URI.pm';

requires 'Catalyst::Plugin::Session' => '0.27';
requires 'URI';
requires 'URI::QueryParam';
requires 'URI::Find';
requires 'HTML::TokeParser::Simple';
requires 'MIME::Types';
requires 'Test::MockObject'          => '1.01';
requires 'MRO::Compat';
requires 'namespace::clean';
requires 'Moose';
requires 'MooseX::Emulate::Class::Accessor::Fast';

test_requires 'Class::Data::Inheritable';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Session-State-URI/';

WriteAll;
