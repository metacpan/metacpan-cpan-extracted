package TestApp;
use Catalyst qw//;
use Moose;

extends 'Catalyst';

__PACKAGE__->config( name => 'TestApp' );

__PACKAGE__->setup();

1;
