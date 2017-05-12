package TestApp;

use strict;
use Catalyst qw/Params::Profile/;

our $VERSION = '0.01';

### XXX make config configurable, so we can test the xmlrpc 
### specific config settings
#TestApp->config( debug => 1 );

TestApp->setup;

1;
