package TestApp;

use strict;
use Catalyst qw[Server Server::XMLRPC];

our $VERSION = '0.01';

### XXX make config configurable, so we can test the xmlrpc 
### specific config settings
TestApp->config( {
        debug => 0,
        xmlrpc => { 'xml_encoding' => 'utf-8' }
    } );

TestApp->setup;

1;
