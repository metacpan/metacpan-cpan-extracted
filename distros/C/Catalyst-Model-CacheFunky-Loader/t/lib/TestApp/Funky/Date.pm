package TestApp::Funky::Date;

use strict;
use base qw/Cache::Funky/;

__PACKAGE__->register( 'now' , sub { time } );

1;
