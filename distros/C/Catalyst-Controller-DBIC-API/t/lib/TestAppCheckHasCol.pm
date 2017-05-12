package TestAppCheckHasCol;
use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.70;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config( name => __PACKAGE__ );

__PACKAGE__->setup;

1;
