package TestApp;

use strict;
use Catalyst 5.80032;

TestApp->config( $ENV{TESTAPP_CONFIG} );

TestApp->setup( @{$ENV{TESTAPP_PLUGINS}} );

1;
