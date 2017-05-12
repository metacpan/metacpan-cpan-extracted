package TestApp;

use strict;
use warnings;

use Catalyst::Runtime;
use Catalyst;

our $VERSION = '0.01';
__PACKAGE__->config( name => 'TestApp' );
__PACKAGE__->setup;

1;
