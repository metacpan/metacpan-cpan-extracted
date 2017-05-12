package TestApp;

use strict;
use warnings;

use Catalyst::Runtime 5.80;

use parent qw/Catalyst/;
use Catalyst qw/ Static::Simple /;

__PACKAGE__->config(
   name => 'TestApp',
);

__PACKAGE__->setup();

1;
