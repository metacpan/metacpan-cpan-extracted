package TestApp;
use strict;
use warnings;

use parent qw/Catalyst/;
use Catalyst qw/
                ConfigLoader
                Static::Simple/;

__PACKAGE__->setup;

1;
