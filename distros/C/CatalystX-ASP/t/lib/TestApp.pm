package TestApp;

use strict;
use warnings;

use Moose;
use Catalyst qw/
    Session
    Session::State::Cookie
    Session::Store::File
    /;

__PACKAGE__->config(
    name              => 'TestApp',
    'Plugin::Session' => {
        cookie_name => "session-id",
        storage     => "/tmp/testapp-sessions",
    },
    'CatalystX::ASP' => {
        Global        => 'root',
        GlobalPackage => 'TestApp::ASP',
        XMLSubsMatch  => '(?:TestApp::ASP::\w+)::\w+',
    },
);

with 'CatalystX::ASP::Role';

__PACKAGE__->setup;
