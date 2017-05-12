package TestApp;

use strict;
use Catalyst;
use Data::Dumper;

our $VERSION = '0.01';

TestApp->config(
    name => 'TestApp',
);

TestApp->setup( qw/RequireSSL/ );

1;
