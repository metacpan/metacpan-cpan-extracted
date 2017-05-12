# Catalyst::Plugin::RequestToken - check module loading and create testing directory

use strict;

use Test::More tests => 1;

BEGIN { use_ok( 'Catalyst::Plugin::RequestToken' ); }

