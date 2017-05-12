package TestApp;

use strict;
use warnings;

use Catalyst qw( I18N I18N::Request );

our $VERSION = '0.01';

TestApp->config( name => 'TestApp', root => '/some/dir' );

TestApp->setup;

1;
