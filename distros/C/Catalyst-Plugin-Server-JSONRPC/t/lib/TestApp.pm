package TestApp;

use strict;
use Catalyst qw[ Server Server::JSONRPC];

our $VERSION = '0.01';

### XXX make config configurable, so we can test the jsonrpc 
### specific config settings
TestApp->config( {
        debug => 1,
        jsonrpc => { 'separator' => '.' }
    } );

TestApp->setup;

1;
