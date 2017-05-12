### Dispatch based jsonrpc server ###
package TestApp;

use strict;
use Catalyst qw[Server Server::JSONRPC];
use base qw[Catalyst];

our $VERSION = '0.01';

### XXX make config configurable, so we can test the jsonrpc 
### specific config settings
TestApp->config( 
);

TestApp->setup;

1;
