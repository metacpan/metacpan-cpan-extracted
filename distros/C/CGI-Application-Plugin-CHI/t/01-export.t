#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

use_ok( 'CGI::Application::Plugin::CHI' );

ok( defined &cache, 'cache method exported' );
ok( defined &rmcache, 'rmcache method exported' );
ok( defined &cache_config, 'cache_config method exported' );
ok( defined &cache_default, 'cache_default method exported' );
