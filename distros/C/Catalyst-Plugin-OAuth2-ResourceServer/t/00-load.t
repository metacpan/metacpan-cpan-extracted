use v5.36;
use Test::More;

# Load every module in the dist, so a syntax error in any of them fails here.
require_ok($_) for qw/
    Catalyst::Plugin::OAuth2::ResourceServer
    Catalyst::Plugin::OAuth2::ResourceServer::Server
    Catalyst::Plugin::OAuth2::ResourceServer::Error
    /;

done_testing;
