package TestApp;

use strict;
use warnings;
use Catalyst;

our $VERSION = '0.01';

# hide debug output at startup
{
    no strict 'refs';
    no warnings;
    *{"Catalyst\::Log\::debug"} = sub { };
    *{"Catalyst\::Log\::info"}  = sub { };
}

TestApp->config(
    name => 'TestApp',
);

TestApp->setup( qw/-Debug StackTrace/ );

1;

