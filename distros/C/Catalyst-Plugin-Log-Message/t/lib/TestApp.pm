package TestApp;

use strict;
use Catalyst qw/Log::Message/;

our $VERSION = '0.01';

### XXX make config configurable, so we can test the xmlrpc 
### specific config settings
#TestApp->config( debug => 0 );

TestApp->setup;

1;
