package TestApp;

use strict;
use warnings;

use Catalyst;
use Path::Class;

our $VERSION = '0.01';

__PACKAGE__->config(
    name            => 'TestApp',
    default_message => 'hi',
    default_view    => 'Pkgconfig'
);

__PACKAGE__->setup;

1;

