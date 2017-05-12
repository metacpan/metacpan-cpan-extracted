package TestApp;

use strict;
use warnings;
use Catalyst;

__PACKAGE__->config($TestApp::CONFIG);
__PACKAGE__->setup(@{ $TestApp::PLUGINS });

1;
