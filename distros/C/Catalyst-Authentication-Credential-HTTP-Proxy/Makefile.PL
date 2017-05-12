use inc::Module::Install 0.87;

name 'Catalyst-Authentication-Credential-HTTP-Proxy';
all_from 'lib/Catalyst/Authentication/Credential/HTTP/Proxy.pm';

requires 'Catalyst::Runtime';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Authentication::Credential::HTTP' => '1.009';
requires 'LWP::Simple';
build_requires 'Test::MockObject';
build_requires 'Test::Exception';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Authentication-Credential-HTTP-Proxy/1.000/trunk/';

WriteAll;

