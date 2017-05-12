use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::AuthorRequires;

license 'perl';

name 'Catalyst-TraitFor-Request-PerLanguageDomains';
all_from 'lib/Catalyst/TraitFor/Request/PerLanguageDomains.pm';

requires 'Catalyst' => '5.80';
requires 'Moose';
requires 'Moose::Autobox';
requires 'MooseX::Types';
requires 'MooseX::Types::Common::String';
requires 'MooseX::Types::Structured';
requires 'I18N::AcceptLanguage';
requires 'namespace::autoclean';

test_requires 'Test::More';
test_requires 'Catalyst::Action::RenderView';
test_requires 'Catalyst::Plugin::Session';
test_requires 'Catalyst::Plugin::Session::State::Cookie';
test_requires 'Catalyst::Plugin::Session::Store::File';
test_requires 'Catalyst::View::TT';
test_requires 'CatalystX::RoleApplicator';
test_requires 'HTTP::Request::Common';

author_requires 'Test::EOL' => '0.3';
author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.08';

resources repository => 'http://github.com/stephan48/Catalyst-TraitFor-Request-PerLanguageDomains/';

tests 't/*.t';
author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/TraitFor/Request/PerLanguageDomains.pm > README") and die $!;
}

WriteAll;

