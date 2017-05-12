package TestApp;

use strict;
use warnings;
use Catalyst;

__PACKAGE__->config($ENV{TESTAPP_CONFIG});
__PACKAGE__->setup(@{ $ENV{TESTAPP_PLUGINS} });

1;
