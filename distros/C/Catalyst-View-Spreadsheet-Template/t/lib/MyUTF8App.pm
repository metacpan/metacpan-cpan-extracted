package MyUTF8App;
use Moose;
use namespace::autoclean;

extends 'Catalyst';

__PACKAGE__->config(
    name => 'MyUTF8App',
);

__PACKAGE__->setup;

1;
