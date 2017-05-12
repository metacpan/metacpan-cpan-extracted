use inc::Module::Install;
name 'Catalyst-Plugin-Authentication-Credential-OpenID';
all_from 'lib/Catalyst/Plugin/Authentication/Credential/OpenID.pm';

requires 'Net::OpenID::Consumer';
requires 'LWPx::ParanoidAgent';
requires 'UNIVERSAL::require';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
