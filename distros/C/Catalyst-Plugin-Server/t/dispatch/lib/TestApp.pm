### Dispatch based xmlrpc server ###
package TestApp;

use strict;
use Catalyst qw[Server Server::XMLRPC];
use base qw[Catalyst];

our $VERSION = '0.01';

### XXX make config configurable, so we can test the xmlrpc 
### specific config settings
TestApp->config( 
);

TestApp->setup;

1;
