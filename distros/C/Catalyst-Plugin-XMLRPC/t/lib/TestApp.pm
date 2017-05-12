package TestApp;

use strict;
use Catalyst qw/XMLRPC/;

our $VERSION = '0.01';

TestApp->config( name => 'TestApp', root => '/some/dir' );

TestApp->setup;

1;
