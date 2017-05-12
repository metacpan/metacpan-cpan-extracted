use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'CatalystX-OAuth2-Provider';
all_from 'lib/CatalystX/OAuth2/Provider.pm';

requires 'Moose';
requires 'CatalystX::InjectComponent';
requires 'CatalystX::Component::Traits';
requires 'Moose::Autobox';
requires 'Catalyst::Controller::ActionRole';
requires 'OAuth::Lite';
requires 'JSON::XS';
requires 'HTTP::Headers::Util';
requires 'Digest::HMAC_SHA1';
requires 'namespace::autoclean';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

test_requires 'Catalyst::Action::RenderView';
test_requires 'Catalyst::Plugin::Authentication';
test_requires 'Catalyst::Plugin::Session';
test_requires 'Catalyst::Plugin::Session::Store::FastMmap';
test_requires 'Catalyst::Plugin::Session::State::Cookie';
test_requires 'Catalyst::Plugin::Session::State::URI';
test_requires 'Catalyst::Plugin::Session::State::Auth';
test_requires 'Catalyst::View::TT';
test_requires 'Catalyst::View::JSON';
test_requires 'JSON::Any';


author_tests 't/author';

resources repository => 'https://github.com/startsiden/catalystx-oauth2-provider';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/CatalystX/OAuth2/Provider.pm > README")
        and die $!;
}

WriteAll();
