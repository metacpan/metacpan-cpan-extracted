use inc::Module::Install;

name     'Catalyst-Authentication-Credential-YubiKey';
all_from 'lib/Catalyst/Authentication/Credential/YubiKey.pm';
author   'Toby Corkindale <tjc@cpan.org>';
license  'perl';

requires 'Catalyst::Exception';
requires 'Moose';
requires 'namespace::autoclean';
requires 'MooseX::Types::Common';
requires 'Auth::Yubikey_WebClient' => '2.00';

build_requires 'Test::More';
build_requires 'Test::Exception';

homepage 'http://github.com/TJC/Catalyst-Authentication-Credential-YubiKey';
resources 'repository' =>
    'git://github.com/TJC/Catalyst-Authentication-Credential-YubiKey.git';

auto_install;

WriteAll;

