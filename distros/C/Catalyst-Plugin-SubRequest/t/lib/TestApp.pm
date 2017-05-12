package TestApp;
use strict;
use warnings;
use base qw/Catalyst/;

use Catalyst qw[SubRequest];

__PACKAGE__->config(
    name=>"subrequest test"
);

__PACKAGE__->setup();

1;
