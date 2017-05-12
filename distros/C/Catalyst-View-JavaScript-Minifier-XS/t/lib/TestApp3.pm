package TestApp3;

use strict;
use warnings;

use Catalyst::Runtime 5.80;

use parent qw/Catalyst/;
use Catalyst;

__PACKAGE__->config(
   name => 'TestApp3',
);

# Start the application
__PACKAGE__->setup();

1;
