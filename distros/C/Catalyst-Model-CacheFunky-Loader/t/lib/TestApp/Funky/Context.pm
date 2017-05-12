package TestApp::Funky::Context;

use strict;
use base qw/Cache::Funky/;

__PACKAGE__->register( 'name' , sub { __PACKAGE__->context->config->{name} } );

1;
