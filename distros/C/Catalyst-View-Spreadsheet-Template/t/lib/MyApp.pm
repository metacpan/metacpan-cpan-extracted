package MyApp;
use Moose;
use namespace::autoclean;

extends 'Catalyst';

__PACKAGE__->config(
    name => 'MyApp',
);

__PACKAGE__->setup;

1;
