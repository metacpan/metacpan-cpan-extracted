use inc::Module::Install;
use Module::Install::ReadmeFromPod;
use Module::Install::AuthorTests;

name     'Catalyst-TraitFor-Request-DecodedParams';
all_from 'lib/Catalyst/TraitFor/Request/DecodedParams.pm';
author   q{Wallace Reis <wreis@cpan.org>};
readme_from;
repository 'git://github.com/wreis/Catalyst-TraitFor-Request-DecodedParams.git';

test_requires 'Test::More';
test_requires 'CatalystX::RoleApplicator';
test_requires 'Catalyst::Runtime' => '5.80029';

requires 'Moose';
requires 'namespace::autoclean';
requires 'JSON::Any';
requires 'Try::Tiny';

author_tests('t/author');

auto_install;

WriteAll;
