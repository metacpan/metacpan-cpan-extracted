package TestApp;
use Moose;
use namespace::autoclean;
use Catalyst;

extends 'Catalyst';

__PACKAGE__->config( default_view => 'D' );

__PACKAGE__->setup;

1;
