package TestApp;

use strict;
use Catalyst qw/I18N/;
use base qw/Catalyst/;

__PACKAGE__->config( name => 'TestApp', root => '/some/dir' );

__PACKAGE__->setup;

1;
