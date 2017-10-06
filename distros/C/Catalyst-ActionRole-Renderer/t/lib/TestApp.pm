package TestApp;

use strict;
use warnings;

use Catalyst;
#use Catalyst::Runtime 5.90;

use parent qw/Catalyst/;
use Catalyst;
our $VERSION = '0.01';

__PACKAGE__->config( 
    name => 'TestApp',
    default_view => 'TT',
);

__PACKAGE__->setup();

1;
