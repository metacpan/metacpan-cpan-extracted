package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

extends 'Catalyst';

our $VERSION = '1.0';
$VERSION = eval $VERSION;

__PACKAGE__->config(                                                          
    name => 'TestApp',     
);

__PACKAGE__->setup;

1;
