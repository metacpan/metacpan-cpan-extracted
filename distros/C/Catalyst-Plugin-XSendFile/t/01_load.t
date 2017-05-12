# -*- perl -*-

# t/01_load.t - check module loading and create testing directory

use Test::More tests => 1;

BEGIN { use_ok( 'Catalyst::Plugin::XSendFile' ); }


