use strict;
use Test::More tests => 2;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
}


BEGIN { use_ok('Catalyst::Plugin::Server::XMLRPC') }
BEGIN { use_ok('Catalyst::Plugin::Server') }
