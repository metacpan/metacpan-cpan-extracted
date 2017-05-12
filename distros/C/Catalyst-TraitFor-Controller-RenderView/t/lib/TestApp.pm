package TestApp;
use strict;
use warnings;
use Catalyst;

use base qw/Catalyst/;

__PACKAGE__->config( name => 'TestApp', root => '/some/dir' );

__PACKAGE__->setup;

1;
